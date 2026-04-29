---@class AITrackerPreview
--- Live diff preview for AI tool calls (Claude Code Edit/Write/MultiEdit).
--- Receives requests from preview-hook.py via the filesystem and lets the
--- user accept/reject inside nvim before the change lands on disk.
local M = {}

local uv = vim.uv or vim.loop

local PENDING_DIR = vim.fn.expand("~/.cache/ai-tracker-pending")
local REQUESTS_DIR = PENDING_DIR .. "/requests"
local RESPONSES_DIR = PENDING_DIR .. "/responses"
local HEARTBEAT = PENDING_DIR .. "/.alive"
local DISABLED = PENDING_DIR .. "/.disabled"

local state = {
	fs_event = nil,
	heartbeat_timer = nil,
	queue = {}, -- pending requests waiting for review
	active = nil, -- request currently displayed
	tab = nil,
	prev_win = nil,
	seen = {}, -- ids we've already pulled into state.queue or processed
}

local function ensure_dirs()
	vim.fn.mkdir(REQUESTS_DIR, "p")
	vim.fn.mkdir(RESPONSES_DIR, "p")
end

local function get_project_root()
	local ok, tracker = pcall(require, "ai-tracker")
	if ok and tracker and tracker.current_project_root then
		local root = tracker.current_project_root()
		if root and root ~= "" then return root end
	end
	return nil
end

local function write_heartbeat()
	ensure_dirs()
	local payload = vim.json.encode({
		pid = vim.fn.getpid(),
		project_root = get_project_root(), -- nil if no project — hook will passthrough
	})
	local f = io.open(HEARTBEAT, "w")
	if f then
		f:write(payload)
		f:close()
	end
end

local function clear_heartbeat()
	pcall(os.remove, HEARTBEAT)
end

local function read_request(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local content = f:read("*a")
	f:close()
	local ok, parsed = pcall(vim.json.decode, content)
	if not ok then return nil end
	return parsed
end

local function write_response(id, decision, reason)
	local payload = vim.json.encode({ decision = decision, reason = reason })
	local final = RESPONSES_DIR .. "/" .. id .. ".json"
	local tmp = final .. ".tmp"
	local f = io.open(tmp, "w")
	if not f then return end
	f:write(payload)
	f:close()
	os.rename(tmp, final)
end

--- Build the diff content for a request.
--- For Edit: shows current file vs file-with-edit-applied.
--- For Write: shows current file vs proposed content.
--- For MultiEdit: applies all edits in memory, shows current vs after.
---@param req table
---@return { old: string[], new: string[], title: string, filetype: string }?
local function build_diff(req)
	local input = req.tool_input or {}
	local file_path = input.file_path
	if not file_path then return nil end

	local function read_file()
		local f = io.open(file_path, "r")
		if not f then return "" end
		local content = f:read("*a") or ""
		f:close()
		return content
	end

	local function detect_ft()
		return vim.filetype.match({ filename = file_path }) or ""
	end

	local mode_suffix = req.permission_mode and req.permission_mode ~= "default"
		and string.format(" [%s]", req.permission_mode)
		or ""
	local title = string.format("%s: %s%s", req.tool_name, vim.fn.fnamemodify(file_path, ":~:."), mode_suffix)

	if req.tool_name == "Edit" then
		local current = read_file()
		local old_string = input.old_string or ""
		local new_string = input.new_string or ""
		-- Apply the edit in memory. If old_string isn't found, fall back to
		-- showing just the snippets so the user still sees something.
		local idx = current:find(old_string, 1, true)
		if idx then
			local proposed = current:sub(1, idx - 1) .. new_string .. current:sub(idx + #old_string)
			return {
				old = vim.split(current, "\n", { plain = true }),
				new = vim.split(proposed, "\n", { plain = true }),
				title = title,
				filetype = detect_ft(),
			}
		else
			return {
				old = vim.split(old_string, "\n", { plain = true }),
				new = vim.split(new_string, "\n", { plain = true }),
				title = title .. " (snippet only — old_string not found)",
				filetype = detect_ft(),
			}
		end
	elseif req.tool_name == "Write" then
		return {
			old = vim.split(read_file(), "\n", { plain = true }),
			new = vim.split(input.content or "", "\n", { plain = true }),
			title = title,
			filetype = detect_ft(),
		}
	elseif req.tool_name == "MultiEdit" then
		local current = read_file()
		local proposed = current
		for _, e in ipairs(input.edits or {}) do
			local idx = proposed:find(e.old_string or "", 1, true)
			if idx then
				proposed = proposed:sub(1, idx - 1) .. (e.new_string or "") .. proposed:sub(idx + #(e.old_string or ""))
			end
		end
		return {
			old = vim.split(current, "\n", { plain = true }),
			new = vim.split(proposed, "\n", { plain = true }),
			title = title,
			filetype = detect_ft(),
		}
	end
	return nil
end

local function make_scratch(name, lines, ft)
	vim.cmd("enew")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	if ft and ft ~= "" then vim.bo[buf].filetype = ft end
	pcall(vim.api.nvim_buf_set_name, buf, name)
	vim.cmd("diffthis")
	return buf
end

local function set_keymaps(buf)
	local opts = { buffer = buf, silent = true, nowait = true }
	vim.keymap.set("n", "<C-a>", function() M.respond("allow") end, vim.tbl_extend("force", opts, { desc = "AI Tracker: accept" }))
	vim.keymap.set("n", "<C-c>", function() M.respond("deny", "Rejected via nvim") end, vim.tbl_extend("force", opts, { desc = "AI Tracker: reject" }))
	vim.keymap.set("n", "q", function() M.respond("deny", "Cancelled") end, opts)
end

local function open_preview(req)
	state.active = req
	state.prev_win = vim.api.nvim_get_current_win()

	local content = build_diff(req)
	if not content then
		M.respond("allow")
		return
	end

	vim.cmd("tabnew")
	state.tab = vim.api.nvim_get_current_tabpage()

	local left = make_scratch("ai-tracker://before", content.old, content.filetype)
	vim.cmd("vsplit")
	local right = make_scratch("ai-tracker://after", content.new, content.filetype)

	set_keymaps(left)
	set_keymaps(right)

	vim.notify(
		string.format("AI Tracker: review %s — <C-a> accept, <C-c> reject, q cancel", content.title),
		vim.log.levels.INFO,
		{ title = "AI Tracker" }
	)
end

local function process_next()
	if state.active then return end
	local req = table.remove(state.queue, 1)
	if not req then return end
	open_preview(req)
end

--- Respond to the active request and process the next one in the queue.
---@param decision "allow"|"deny"
---@param reason? string
function M.respond(decision, reason)
	if not state.active then return end
	write_response(state.active.id, decision, reason)

	local prev = state.prev_win
	if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) then
		pcall(vim.cmd, "tabclose")
	end
	if prev and vim.api.nvim_win_is_valid(prev) then
		pcall(vim.api.nvim_set_current_win, prev)
	end

	state.active = nil
	state.tab = nil
	state.prev_win = nil

	vim.schedule(process_next)
end

local function scan_requests()
	local handle = uv.fs_scandir(REQUESTS_DIR)
	if not handle then return end
	local picked = false
	while true do
		local name = uv.fs_scandir_next(handle)
		if not name then break end
		if name:match("%.json$") and not name:match("%.tmp$") then
			local id = name:gsub("%.json$", "")
			if not state.seen[id] then
				local req = read_request(REQUESTS_DIR .. "/" .. name)
				if req and req.id then
					state.seen[req.id] = true
					table.insert(state.queue, req)
					picked = true
				end
			end
		end
	end
	if picked then vim.schedule(process_next) end
end

--- Start the preview module: heartbeat, fs_event on requests dir.
function M.start()
	ensure_dirs()
	write_heartbeat()
	vim.schedule(scan_requests)

	state.fs_event = uv.new_fs_event()
	pcall(function()
		state.fs_event:start(REQUESTS_DIR, {}, vim.schedule_wrap(function(err)
			if err then return end
			scan_requests()
		end))
	end)

	-- Refresh heartbeat every 2s so the hook can detect a stale/dead nvim.
	-- Also a safety scan in case fs_event misses an event.
	state.heartbeat_timer = uv.new_timer()
	state.heartbeat_timer:start(
		2000,
		2000,
		vim.schedule_wrap(function()
			write_heartbeat()
			scan_requests()
		end)
	)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function() M.stop() end,
	})
end

--- Stop the module: deny any pending requests, clear heartbeat.
function M.stop()
	if state.fs_event then
		pcall(function()
			state.fs_event:stop()
			state.fs_event:close()
		end)
		state.fs_event = nil
	end
	if state.heartbeat_timer then
		pcall(function()
			state.heartbeat_timer:stop()
			state.heartbeat_timer:close()
		end)
		state.heartbeat_timer = nil
	end
	if state.active then
		write_response(state.active.id, "deny", "nvim shutdown")
		state.active = nil
	end
	for _, req in ipairs(state.queue) do
		write_response(req.id, "deny", "nvim shutdown")
	end
	state.queue = {}
	clear_heartbeat()
end

--- Is the preview gate currently enabled?
---@return boolean
function M.is_enabled()
	return vim.fn.filereadable(DISABLED) == 0
end

--- Toggle the preview gate. When disabled, the hook passes through and
--- Claude proceeds without nvim review (useful for auto-accept sessions).
--- State persists across nvim restarts via ~/.cache/ai-tracker-pending/.disabled.
function M.toggle()
	if M.is_enabled() then
		ensure_dirs()
		local f = io.open(DISABLED, "w")
		if f then
			f:close()
		end
		vim.notify("AI Tracker preview: DISABLED (hook will pass through)", vim.log.levels.WARN, { title = "AI Tracker" })
	else
		pcall(os.remove, DISABLED)
		vim.notify("AI Tracker preview: ENABLED", vim.log.levels.INFO, { title = "AI Tracker" })
	end
end

--- Path to the hook script (for the install command).
function M.hook_path()
	local source = debug.getinfo(1, "S").source:sub(2)
	local dir = vim.fn.fnamemodify(source, ":h")
	return dir .. "/preview-hook.py"
end

return M
