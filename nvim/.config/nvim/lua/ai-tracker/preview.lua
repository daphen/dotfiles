---@class AITrackerPreview
--- Live diff preview for AI tool calls (Claude Code Edit/Write/MultiEdit).
--- Receives requests from preview-hook.py via the filesystem and lets the
--- user accept/reject inside nvim before the change lands on disk.
local M = {}

local utils = require("ai-tracker.utils")
local uv = vim.uv or vim.loop

local PENDING_DIR = vim.fn.expand("~/.cache/ai-tracker-pending")
local REQUESTS_ROOT = PENDING_DIR .. "/requests"
local RESPONSES_DIR = PENDING_DIR .. "/responses"
local HEARTBEATS_DIR = PENDING_DIR .. "/heartbeats"
local DISABLED = PENDING_DIR .. "/.disabled"
local PAUSED = PENDING_DIR .. "/.paused"

local function own_pid() return vim.fn.getpid() end
local function own_heartbeat_path() return HEARTBEATS_DIR .. "/" .. own_pid() .. ".json" end
local function own_requests_dir() return REQUESTS_ROOT .. "/" .. own_pid() end

local state = {
	fs_event = nil,
	heartbeat_timer = nil,
	queue = {}, -- pending requests waiting for review
	active = nil, -- request currently displayed
	tab = nil,
	prev_win = nil,
	seen = {}, -- ids we've already pulled into state.queue or processed
	regions = {}, -- list of { start_line, end_line, new_lines } for the active preview
	current_region_idx = 1,
}

-- Cached values populated by background tasks; the heartbeat just reads
-- these so it never blocks on a subprocess.
local _cached_workspace_id = nil
local _cached_common_dir = nil -- { project_root = ..., value = ... }

local function ensure_dirs()
	vim.fn.mkdir(own_requests_dir(), "p")
	vim.fn.mkdir(RESPONSES_DIR, "p")
	vim.fn.mkdir(HEARTBEATS_DIR, "p")
end

--- Read the user's custom theme palette from ~/.config/themes/colors.json.
--- Returns the palette dict for the active background mode, or nil.
local function read_theme_palette()
	local path = vim.fn.expand("~/.config/themes/colors.json")
	local f = io.open(path, "r")
	if not f then return nil end
	local content = f:read("*a")
	f:close()
	local ok, data = pcall(vim.json.decode, content)
	if not ok or type(data) ~= "table" then return nil end
	local mode = vim.o.background == "light" and "light" or "dark"
	local theme = data.themes and data.themes[mode]
	return theme
end

local function setup_highlights()
	local theme = read_theme_palette()
	local is_dark = vim.o.background ~= "light"
	local add_bg = theme and theme.background and theme.background.success
		or (is_dark and "#1f3a23" or "#cfeacf")
	local del_bg = theme and theme.background and theme.background.error
		or (is_dark and "#3e1c24" or "#f4cdcd")
	vim.api.nvim_set_hl(0, "AITrackerDiffAdd", { bg = add_bg, default = true })
	vim.api.nvim_set_hl(0, "AITrackerDiffDel", { bg = del_bg, default = true })
end

local function get_project_root()
	local ok, tracker = pcall(require, "ai-tracker")
	if ok and tracker and tracker.current_project_root then
		local root = tracker.current_project_root()
		if root and root ~= "" then return root end
	end
	return nil
end

--- Return the absolute git common dir for a path (the shared `.git` dir
--- for all worktrees of the same repo). Returns nil if not in a git repo.
---@param path string
---@return string?
local function git_common_dir_for(path)
	if not path or path == "" then return nil end
	local cmd = string.format("git -C %s rev-parse --git-common-dir 2>/dev/null", vim.fn.shellescape(path))
	local out = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then return nil end
	out = out:gsub("\n", "")
	if out == "" then return nil end
	if not vim.startswith(out, "/") then out = path .. "/" .. out end
	return vim.fn.resolve(out)
end

--- Read /proc/<pid>/status and return the parent PID, or nil.
---@param pid integer
---@return integer?
local function read_ppid(pid)
	local f = io.open("/proc/" .. tostring(pid) .. "/status", "r")
	if not f then return nil end
	for line in f:lines() do
		local ppid = line:match("^PPid:%s+(%d+)")
		if ppid then
			f:close()
			return tonumber(ppid)
		end
	end
	f:close()
	return nil
end

--- Query niri for the list of windows. Returns nil if niri isn't running or
--- the command fails (so we fall back gracefully on other compositors).
---@return table[]?
local function niri_windows()
	local out = vim.fn.system("niri msg --json windows 2>/dev/null")
	if vim.v.shell_error ~= 0 or out == "" then return nil end
	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" then return nil end
	return data
end

--- Walk up the process tree from our pid using a precomputed pid→ws map.
---@param pid_to_ws table<integer, integer>
---@return integer?
local function workspace_from_map(pid_to_ws)
	local current = own_pid()
	local depth = 0
	while current and current ~= 1 and depth < 50 do
		if pid_to_ws[current] then return pid_to_ws[current] end
		current = read_ppid(current)
		depth = depth + 1
	end
	return nil
end

--- Refresh the cached niri workspace_id asynchronously so the heartbeat
--- never blocks on the subprocess. Falls back to a sync call on older nvims
--- without vim.system.
local function refresh_workspace_id_async()
	if not vim.system then
		local ws = niri_windows()
		if ws then
			local pid_to_ws = {}
			for _, w in ipairs(ws) do
				if w.pid and w.workspace_id then pid_to_ws[w.pid] = w.workspace_id end
			end
			_cached_workspace_id = workspace_from_map(pid_to_ws)
		end
		return
	end
	vim.system({ "niri", "msg", "--json", "windows" }, { text = true, timeout = 2000 }, function(obj)
		if obj.code ~= 0 or not obj.stdout or obj.stdout == "" then return end
		local ok, data = pcall(vim.json.decode, obj.stdout)
		if not ok or type(data) ~= "table" then return end
		local pid_to_ws = {}
		for _, w in ipairs(data) do
			if w.pid and w.workspace_id then pid_to_ws[w.pid] = w.workspace_id end
		end
		vim.schedule(function() _cached_workspace_id = workspace_from_map(pid_to_ws) end)
	end)
end

--- Cached git common dir for a project root. Common dir basically never
--- changes for a given root, so we compute it once and never refresh.
---@param project_root string
---@return string?
local function cached_common_dir(project_root)
	if _cached_common_dir and _cached_common_dir.project_root == project_root then
		return _cached_common_dir.value
	end
	_cached_common_dir = { project_root = project_root, value = git_common_dir_for(project_root) }
	return _cached_common_dir.value
end

local function write_heartbeat()
	ensure_dirs()
	local project_root = get_project_root()
	local payload = vim.json.encode({
		pid = own_pid(),
		project_root = project_root, -- nil if no project — hook will passthrough
		niri_workspace_id = _cached_workspace_id, -- updated async, no blocking call here
		git_common_dir = project_root and cached_common_dir(project_root) or nil,
	})
	local f = io.open(own_heartbeat_path(), "w")
	if f then
		f:write(payload)
		f:close()
	end
end

local function clear_heartbeat()
	pcall(os.remove, own_heartbeat_path())
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

--- Compute the inline-diff region for an Edit tool call by locating the
--- old_string in the current file content. Returns nil if not found, signaling
--- the caller to fall back to split-mode.
---@param req table
---@return { start_line: integer, end_line: integer, new_lines: string[] }?
local function compute_edit_region(req)
	local input = req.tool_input or {}
	local file_path = input.file_path
	if not file_path or vim.fn.filereadable(file_path) == 0 then return nil end

	local f = io.open(file_path, "r")
	if not f then return nil end
	local content = f:read("*a") or ""
	f:close()

	local old_str = input.old_string or ""
	local new_str = input.new_string or ""
	if old_str == "" then return nil end

	local idx = content:find(old_str, 1, true)
	if not idx then return nil end

	-- Convert byte index → line numbers (1-based).
	local before = content:sub(1, idx - 1)
	local _, before_nl = before:gsub("\n", "")
	local _, old_nl = old_str:gsub("\n", "")
	local start_line = before_nl + 1
	local end_line = start_line + old_nl

	return {
		start_line = start_line,
		end_line = end_line,
		new_lines = vim.split(new_str, "\n", { plain = true }),
	}
end

--- Open the target file in the current window, draw an inline overlay
--- (DiffDelete on removed lines + virt_lines for added content), and arm
--- accept/reject keymaps. Used for Edit tool calls.
---@param req table
---@param region { start_line: integer, end_line: integer, new_lines: string[] }
local function open_preview_inline(req, region)
	local file_path = req.tool_input.file_path

	-- Save current state so we can restore on respond.
	state.prev_win = vim.api.nvim_get_current_win()
	state.prev_buf = vim.api.nvim_get_current_buf()
	state.prev_pos = vim.api.nvim_win_get_cursor(state.prev_win)

	local target_bufnr = vim.fn.bufnr(file_path)
	if target_bufnr > 0 and vim.api.nvim_buf_is_loaded(target_bufnr) then
		pcall(vim.cmd, "buffer " .. target_bufnr)
	else
		pcall(vim.cmd, "edit " .. vim.fn.fnameescape(file_path))
		target_bufnr = vim.api.nvim_get_current_buf()
	end

	state.target_bufnr = target_bufnr
	state.ns = vim.api.nvim_create_namespace("ai_tracker_preview")
	state.regions = { region }
	state.current_region_idx = 1
	vim.api.nvim_buf_clear_namespace(target_bufnr, state.ns, 0, -1)

	-- Highlight removed lines with a full-line red background.
	for ln = region.start_line - 1, region.end_line - 1 do
		pcall(vim.api.nvim_buf_set_extmark, target_bufnr, state.ns, ln, 0, {
			line_hl_group = "AITrackerDiffDel",
			priority = 200,
		})
	end

	-- Render added lines as virtual text below the removed block.
	-- Pad each virt_line to the window width so the green bg fills the row.
	if #region.new_lines > 0 then
		local virt_lines = {}
		local win_width = vim.api.nvim_win_get_width(0)
		for _, line in ipairs(region.new_lines) do
			local visible_w = vim.fn.strdisplaywidth(line)
			local pad = string.rep(" ", math.max(0, win_width - visible_w))
			table.insert(virt_lines, { { line .. pad, "AITrackerDiffAdd" } })
		end
		pcall(vim.api.nvim_buf_set_extmark, target_bufnr, state.ns, region.end_line - 1, 0, {
			virt_lines = virt_lines,
			virt_lines_above = false,
		})
	end

	utils.jump_to_line(region.start_line)

	set_keymaps(target_bufnr)

	local mode_suffix = req.permission_mode and req.permission_mode ~= "default"
		and string.format(" [%s]", req.permission_mode)
		or ""
	vim.notify(
		string.format(
			"AI Tracker: review Edit %s%s — <C-a> accept, <C-c> reject, q cancel",
			vim.fn.fnamemodify(file_path, ":~:."),
			mode_suffix
		),
		vim.log.levels.INFO,
		{ title = "AI Tracker" }
	)
end

--- Side-by-side fallback: open a new tab with before/after scratch buffers
--- in diff mode. Used for Write/MultiEdit and as a fallback when the inline
--- overlay can't locate the edit region.
---@param req table
local function open_preview_split(req)
	local content = build_diff(req)
	if not content then
		M.respond("allow")
		return
	end

	state.prev_win = vim.api.nvim_get_current_win()

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

--- Dispatch a request to inline-overlay (Edit) or split (Write/MultiEdit).
---@param req table
local function open_preview(req)
	state.active = req

	if req.tool_name == "Edit" then
		local region = compute_edit_region(req)
		if region then
			open_preview_inline(req, region)
			return
		end
		-- old_string not found in file (probably already mutated since the
		-- agent computed it) — fall back to side-by-side.
	end

	open_preview_split(req)
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

	-- Inline-overlay cleanup: clear extmarks, drop buffer-local keymaps,
	-- restore the buffer the user was on (unless that buffer IS the target).
	if state.target_bufnr and state.ns then
		pcall(vim.api.nvim_buf_clear_namespace, state.target_bufnr, state.ns, 0, -1)
		for _, key in ipairs({ "<C-a>", "<C-c>", "q" }) do
			pcall(vim.keymap.del, "n", key, { buffer = state.target_bufnr })
		end
		if
			state.prev_win
			and vim.api.nvim_win_is_valid(state.prev_win)
			and state.prev_buf
			and state.prev_buf ~= state.target_bufnr
			and vim.api.nvim_buf_is_valid(state.prev_buf)
		then
			pcall(vim.api.nvim_win_set_buf, state.prev_win, state.prev_buf)
			if state.prev_pos then
				pcall(vim.api.nvim_win_set_cursor, state.prev_win, state.prev_pos)
			end
		end
	end

	-- Split-mode cleanup: close the diff tab.
	if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) then
		pcall(vim.cmd, "tabclose")
		if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
			pcall(vim.api.nvim_set_current_win, state.prev_win)
		end
	end

	state.active = nil
	state.tab = nil
	state.target_bufnr = nil
	state.ns = nil
	state.prev_win = nil
	state.prev_buf = nil
	state.prev_pos = nil
	state.regions = {}
	state.current_region_idx = 1

	vim.schedule(process_next)
end

local function scan_requests()
	local dir = own_requests_dir()
	local handle = uv.fs_scandir(dir)
	if not handle then return end
	local picked = false
	while true do
		local name = uv.fs_scandir_next(handle)
		if not name then break end
		if name:match("%.json$") and not name:match("%.tmp$") then
			local id = name:gsub("%.json$", "")
			if not state.seen[id] then
				local req = read_request(dir .. "/" .. name)
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
	setup_highlights()
	-- Kick off the first niri query async so the heartbeat doesn't have to
	-- wait. Until it returns, niri_workspace_id is nil — that's fine, the
	-- hook treats unknown workspace as "skip the workspace filter."
	refresh_workspace_id_async()
	-- Re-check workspace whenever nvim regains terminal focus. Moving a
	-- window between niri workspaces practically always involves a focus
	-- change, so this is enough to keep the cache current without polling.
	vim.api.nvim_create_autocmd("FocusGained", {
		group = vim.api.nvim_create_augroup("AITrackerPreviewWorkspace", { clear = true }),
		callback = refresh_workspace_id_async,
	})

	write_heartbeat()
	vim.schedule(scan_requests)

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("AITrackerPreviewHl", { clear = true }),
		callback = setup_highlights,
	})

	state.fs_event = uv.new_fs_event()
	pcall(function()
		state.fs_event:start(own_requests_dir(), {}, vim.schedule_wrap(function(err)
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

--- Jump to the next AI chunk in the active preview, or fall back to
--- gitsigns next-hunk if there's no multi-chunk preview active here.
function M.next_chunk()
	if
		state.target_bufnr
		and vim.api.nvim_get_current_buf() == state.target_bufnr
		and #state.regions > 1
	then
		state.current_region_idx = (state.current_region_idx % #state.regions) + 1
		utils.jump_to_line(state.regions[state.current_region_idx].start_line)
		return
	end
	local ok, gs = pcall(require, "gitsigns")
	if ok and gs.next_hunk then gs.next_hunk() end
end

--- Jump to the previous AI chunk in the active preview, or fall back to
--- gitsigns prev-hunk.
function M.prev_chunk()
	if
		state.target_bufnr
		and vim.api.nvim_get_current_buf() == state.target_bufnr
		and #state.regions > 1
	then
		state.current_region_idx = ((state.current_region_idx - 2) % #state.regions) + 1
		utils.jump_to_line(state.regions[state.current_region_idx].start_line)
		return
	end
	local ok, gs = pcall(require, "gitsigns")
	if ok and gs.prev_hunk then gs.prev_hunk() end
end

--- Resolve the chunk currently under the cursor for "ask Claude about this."
--- Priority: active AI preview region > gitsigns hunk > current line.
---@return { lines: string[], start_line: integer, end_line: integer }
local function chunk_under_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local cur_line = vim.fn.line(".")

	-- 1. Active AI preview region in this buffer.
	if state.target_bufnr == bufnr and state.regions and #state.regions > 0 then
		for _, r in ipairs(state.regions) do
			if cur_line >= r.start_line and cur_line <= r.end_line then
				return {
					lines = vim.api.nvim_buf_get_lines(bufnr, r.start_line - 1, r.end_line, false),
					start_line = r.start_line,
					end_line = r.end_line,
				}
			end
		end
	end

	-- 2. Gitsigns hunk under cursor (covers anything uncommitted in any project).
	local ok, gs = pcall(require, "gitsigns")
	if ok and gs.get_hunks then
		local hunks = gs.get_hunks(bufnr) or {}
		for _, h in ipairs(hunks) do
			local s, c = h.added and h.added.start, h.added and h.added.count
			if s and c and c > 0 and cur_line >= s and cur_line < s + c then
				return {
					lines = vim.api.nvim_buf_get_lines(bufnr, s - 1, s + c - 1, false),
					start_line = s,
					end_line = s + c - 1,
				}
			end
		end
	end

	-- 3. Fallback: just the current line.
	return {
		lines = vim.api.nvim_buf_get_lines(bufnr, cur_line - 1, cur_line, false),
		start_line = cur_line,
		end_line = cur_line,
	}
end

--- Look up an ai-tracker channel server matching our niri workspace.
--- This is the most reliable path — each Claude session spawns its own
--- channel as a child process, so the registry maps unambiguously.
---@return { port: integer, claude_pid: integer }?
local function claude_channel_from_registry()
	local channels_dir = PENDING_DIR .. "/channels"
	local handle = uv.fs_scandir(channels_dir)
	if not handle then return nil end

	local our_ws = _cached_workspace_id
	local fallback
	while true do
		local name = uv.fs_scandir_next(handle)
		if not name then break end
		if name:match("%.json$") then
			local f = io.open(channels_dir .. "/" .. name, "r")
			if f then
				local content = f:read("*a")
				f:close()
				local ok, record = pcall(vim.json.decode, content)
				if ok and record and record.port and record.claude_pid then
					vim.fn.system(string.format("kill -0 %d 2>/dev/null", record.claude_pid))
					if vim.v.shell_error == 0 then
						-- Match workspace if both sides know; otherwise accept.
						if our_ws and record.niri_workspace_id and our_ws == record.niri_workspace_id then
							return { port = record.port, claude_pid = record.claude_pid }
						end
						if not fallback then
							fallback = { port = record.port, claude_pid = record.claude_pid }
						end
					else
						-- Dead Claude — clean up stale registry entry.
						pcall(os.remove, channels_dir .. "/" .. name)
					end
				end
			end
		end
	end
	return fallback
end

--- POST a JSON ask payload to the channel server's HTTP listener. Returns
--- true on success.
---@param port integer
---@param payload table
---@return boolean
local function channel_post(port, payload)
	local body = vim.json.encode(payload)
	local cmd = string.format(
		"curl -s --max-time 3 -X POST -H 'Content-Type: application/json' --data-binary @- 'http://127.0.0.1:%d/'",
		port
	)
	local job = io.popen(cmd, "w")
	if not job then return false end
	job:write(body)
	local ok = job:close()
	return ok == true
end

--- Look up Claude's kitty window from the session registry written by the
--- hook. This is the kitty fallback — used when no channel is available.
--- Returns nil if the registry has no entry for our workspace or it's stale.
---@return integer?
local function claude_window_from_registry()
	local sessions_dir = PENDING_DIR .. "/claude-sessions"
	-- Try our workspace first, then fall back to "default" (no-niri case).
	local keys = {}
	if _cached_workspace_id then table.insert(keys, tostring(_cached_workspace_id)) end
	table.insert(keys, "default")

	for _, key in ipairs(keys) do
		local path = sessions_dir .. "/" .. key .. ".json"
		local f = io.open(path, "r")
		if f then
			local content = f:read("*a")
			f:close()
			local ok, record = pcall(vim.json.decode, content)
			if ok and record and record.kitty_window_id then
				-- Verify the recorded Claude pid is still alive.
				local pid = record.pid
				if type(pid) == "number" then
					local alive_check = vim.fn.system(string.format("kill -0 %d 2>/dev/null", pid))
					if vim.v.shell_error == 0 then
						return record.kitty_window_id
					end
				end
			end
		end
	end
	return nil
end

--- Find the kitty window running a Claude Code session. First consults the
--- registry written by preview-hook.py (authoritative — it knows Claude's
--- exact pid). Falls back to scanning kitty windows by process name only if
--- the registry has no record (e.g. Claude hasn't done any tool calls yet).
---@return integer?
local function find_claude_kitty_window()
	local from_registry = claude_window_from_registry()
	if from_registry then return from_registry end
	local out = vim.fn.system("kitten @ ls 2>/dev/null")
	if vim.v.shell_error ~= 0 or out == "" then return nil end
	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" then return nil end

	-- Build set of pids that are in our niri workspace (if known) so we can
	-- prefer those.
	local same_ws_pids = {}
	if _cached_workspace_id then
		local windows = niri_windows()
		if windows then
			for _, w in ipairs(windows) do
				if w.workspace_id == _cached_workspace_id and w.pid then
					same_ws_pids[w.pid] = true
				end
			end
		end
	end

	local fallback
	for _, os_window in ipairs(data) do
		local os_pid = os_window.os_window_id and os_window.platform_window_id
		for _, tab in ipairs(os_window.tabs or {}) do
			for _, window in ipairs(tab.windows or {}) do
				for _, proc in ipairs(window.foreground_processes or {}) do
					local cmdline = proc.cmdline or {}
					local first = cmdline[1] or ""
					if first:lower():match("claude") then
						-- Prefer windows whose top-level kitty pid is in our niri ws.
						if next(same_ws_pids) and same_ws_pids[os_window.pid] then
							return window.id
						end
						fallback = fallback or window.id
					end
				end
			end
		end
	end
	return fallback
end

--- Send text into a kitty window via remote control. Returns true on
--- success. Does NOT press enter — user reviews + submits manually.
---@param window_id integer
---@param text string
---@return boolean
local function kitty_send_text(window_id, text)
	-- Use stdin to avoid argv quoting nightmares for multi-line content.
	local cmd = string.format("kitten @ send-text --match id:%d --stdin", window_id)
	local job = io.popen(cmd, "w")
	if not job then return false end
	job:write(text)
	local ok = job:close()
	return ok == true
end

--- Prompt for a question, then send "<question>\n\nFile: <path>:<lines>\n\n```<ft>\n<chunk>\n```"
--- directly into Claude's kitty window via remote control. Falls back to the
--- system clipboard if kitty isn't available or no Claude window is found.
function M.ask_about_chunk()
	local bufnr = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(bufnr)
	if file_path == "" then
		vim.notify("AI Tracker: no file in this buffer", vim.log.levels.WARN)
		return
	end

	local chunk = chunk_under_cursor()

	vim.ui.input({ prompt = "Ask Claude about this chunk: " }, function(question)
		if not question or question == "" then return end

		local rel_path = vim.fn.fnamemodify(file_path, ":~:.")
		local ft = vim.bo[bufnr].filetype or ""
		local range = chunk.start_line == chunk.end_line
			and tostring(chunk.start_line)
			or string.format("%d-%d", chunk.start_line, chunk.end_line)

		local body = string.format(
			"%s\n\nFile: %s:%s\n\n```%s\n%s\n```\n",
			question,
			rel_path,
			range,
			ft,
			table.concat(chunk.lines, "\n")
		)

		local file_short = vim.fn.fnamemodify(file_path, ":t")
		local n_lines = #chunk.lines
		local lines_word = n_lines == 1 and "line" or "lines"

		-- Preferred: send via the ai-tracker channel (real protocol, no
		-- keystroke emulation, addresses Claude unambiguously by pid).
		local channel = claude_channel_from_registry()
		if channel then
			local payload = {
				question = question,
				file = rel_path,
				lines = range,
				content = table.concat(chunk.lines, "\n"),
				filetype = ft,
			}
			if channel_post(channel.port, payload) then
				vim.notify(
					string.format(
						"Sent to Claude (%d %s, %s:%s) via channel",
						n_lines, lines_word, file_short, range
					),
					vim.log.levels.INFO,
					{ title = "AI Tracker" }
				)
				return
			end
		end

		-- Fallback: kitty keystroke emulation (works without channel setup).
		local claude_win = find_claude_kitty_window()
		if claude_win and kitty_send_text(claude_win, body) then
			vim.notify(
				string.format(
					"Sent to Claude (%d %s, %s:%s) — review and press Enter in Claude window",
					n_lines, lines_word, file_short, range
				),
				vim.log.levels.INFO,
				{ title = "AI Tracker" }
			)
			return
		end

		-- Fallback: clipboard.
		vim.fn.setreg("+", body)
		vim.fn.setreg('"', body)
		vim.notify(
			string.format(
				"No Claude kitty window found — copied to clipboard (%d %s, %s:%s)",
				n_lines, lines_word, file_short, range
			),
			vim.log.levels.WARN,
			{ title = "AI Tracker" }
		)
	end)
end

--- Is the preview gate currently enabled?
---@return boolean
function M.is_enabled()
	return vim.fn.filereadable(DISABLED) == 0
end

--- Is Claude currently paused (all tool calls denied)?
---@return boolean
function M.is_paused()
	return vim.fn.filereadable(PAUSED) == 1
end

--- Toggle the global pause state. When paused, the hook denies every tool
--- call regardless of mode, the active preview is auto-rejected, and any
--- queued requests are drained with a deny response. State persists across
--- nvim restarts via ~/.cache/ai-tracker-pending/.paused.
function M.toggle_pause()
	if M.is_paused() then
		pcall(os.remove, PAUSED)
		vim.notify("AI Tracker: RESUMED", vim.log.levels.INFO, { title = "AI Tracker" })
	else
		ensure_dirs()
		local f = io.open(PAUSED, "w")
		if f then f:close() end

		-- Reject the active preview (if any) and drain the queue so any
		-- in-flight hooks unblock immediately instead of timing out.
		if state.active then M.respond("deny", "Edits paused via nvim") end
		for _, req in ipairs(state.queue) do
			write_response(req.id, "deny", "Edits paused via nvim")
		end
		state.queue = {}

		vim.notify(
			"AI Tracker: PAUSED — Claude file edits will be denied; reads/bash still allowed (toggle off with <C-g><leader>)",
			vim.log.levels.WARN,
			{ title = "AI Tracker" }
		)
	end
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
