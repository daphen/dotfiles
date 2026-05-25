--[[
hunk-nvim/signs — draw gitsigns-style diff overlays in nvim buffers using
hunk's session data directly. Bypasses git entirely, so it works even in
sandboxes with broken/shallow git history where gitsigns silently fails.

Data source: `hunk session review --repo X --include-patch --output json`
returns per-file unified diff patches. We parse those into per-line
classifications (add/change/delete) and draw extmarks accordingly.

Refreshes on BufEnter / BufWritePost / InsertLeave with a small debounce.
Hunk daemon is local so calls are cheap.
]]

local M = {}

M.config = {
	linehl = true,
	debounce_ms = 200,
	hunk_bin = "hunk",
}

local NS = vim.api.nvim_create_namespace("hunk-signs")

local state = {
	enabled = false,
	repo_root = nil,
	debounce_timers = {},
}

local function fetch_review()
	if not state.repo_root then return nil end
	local out = vim.fn.system({
		M.config.hunk_bin, "session", "review",
		"--repo", state.repo_root,
		"--include-patch",
		"--output", "json",
	})
	if vim.v.shell_error ~= 0 then return nil end
	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" or not data.review then return nil end
	return data.review
end

-- Parse a unified diff patch into per-line classifications keyed by
-- new-file line number. Values: "add" | "change" | "delete_below" | "topdelete".
local function parse_patch(patch)
	local marks = {}
	if not patch or patch == "" then return marks end
	local current_new = nil
	local pending_delete = 0

	for line in (patch .. "\n"):gmatch("([^\n]*)\n") do
		local n_start = line:match("^@@ %-%d+,?%d* %+(%d+)")
		if n_start then
			current_new = tonumber(n_start)
			pending_delete = 0
		elseif current_new then
			local first = line:sub(1, 1)
			if first == "+" and line:sub(1, 3) ~= "+++" then
				if pending_delete > 0 then
					marks[current_new] = "change"
					pending_delete = pending_delete - 1
				else
					marks[current_new] = marks[current_new] or "add"
				end
				current_new = current_new + 1
			elseif first == "-" and line:sub(1, 3) ~= "---" then
				pending_delete = pending_delete + 1
			elseif first == " " or first == "" then
				if pending_delete > 0 then
					local prev = current_new - 1
					if prev >= 1 then
						if marks[prev] == nil then marks[prev] = "delete_below" end
					else
						marks[current_new] = "topdelete"
					end
					pending_delete = 0
				end
				current_new = current_new + 1
			end
		end
	end
	if current_new and pending_delete > 0 then
		local prev = current_new - 1
		if prev >= 1 and marks[prev] == nil then marks[prev] = "delete_below" end
	end
	return marks
end

local function kind_to_extmark(kind)
	local sign_text, sign_hl, line_hl
	if kind == "add" then
		sign_text = "│"; sign_hl = "GitSignsAdd"
		line_hl = M.config.linehl and "GitSignsAddLn" or nil
	elseif kind == "change" then
		sign_text = "│"; sign_hl = "GitSignsChange"
		line_hl = M.config.linehl and "GitSignsChangeLn" or nil
	elseif kind == "delete_below" then
		sign_text = "_"; sign_hl = "GitSignsDelete"
	elseif kind == "topdelete" then
		sign_text = "‾"; sign_hl = "GitSignsDelete"
	end
	return sign_text, sign_hl, line_hl
end

local function draw_marks(bufnr, marks)
	vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	for ln, kind in pairs(marks) do
		if ln >= 1 and ln <= line_count then
			local sign_text, sign_hl, line_hl = kind_to_extmark(kind)
			pcall(vim.api.nvim_buf_set_extmark, bufnr, NS, ln - 1, 0, {
				sign_text = sign_text,
				sign_hl_group = sign_hl,
				line_hl_group = line_hl,
				invalidate = true,
			})
		end
	end
end

function M.refresh(bufnr)
	if not state.enabled then return end
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_loaded(bufnr) then return end
	local abs = vim.api.nvim_buf_get_name(bufnr)
	if abs == "" or not state.repo_root then return end
	local prefix = state.repo_root .. "/"
	if abs:sub(1, #prefix) ~= prefix then return end
	local relpath = abs:sub(#prefix + 1)

	local review = fetch_review()
	if not review then
		vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
		return
	end

	local file_entry
	for _, f in ipairs(review.files or {}) do
		if f.path == relpath then file_entry = f; break end
	end
	if not file_entry or not file_entry.patch then
		vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
		return
	end

	draw_marks(bufnr, parse_patch(file_entry.patch))
end

local function debounced_refresh(bufnr)
	local t = state.debounce_timers[bufnr]
	if t then t:stop() end
	state.debounce_timers[bufnr] = vim.defer_fn(function()
		state.debounce_timers[bufnr] = nil
		M.refresh(bufnr)
	end, M.config.debounce_ms)
end

local function get_hunk_starts(bufnr)
	local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, NS, 0, -1, {})
	local lines = {}
	for _, m in ipairs(extmarks) do table.insert(lines, m[2] + 1) end
	table.sort(lines)
	local starts = {}
	local last = nil
	for _, ln in ipairs(lines) do
		if last == nil or ln > last + 1 then table.insert(starts, ln) end
		last = ln
	end
	return starts
end

function M.next_hunk()
	local bufnr = vim.api.nvim_get_current_buf()
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local starts = get_hunk_starts(bufnr)
	for _, ln in ipairs(starts) do
		if ln > cur then vim.api.nvim_win_set_cursor(0, { ln, 0 }); return end
	end
	if #starts > 0 then vim.api.nvim_win_set_cursor(0, { starts[1], 0 }) end
end

function M.prev_hunk()
	local bufnr = vim.api.nvim_get_current_buf()
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local starts = get_hunk_starts(bufnr)
	for i = #starts, 1, -1 do
		if starts[i] < cur then vim.api.nvim_win_set_cursor(0, { starts[i], 0 }); return end
	end
	if #starts > 0 then vim.api.nvim_win_set_cursor(0, { starts[#starts], 0 }) end
end

function M.toggle_linehl()
	M.config.linehl = not M.config.linehl
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then M.refresh(bufnr) end
	end
end

function M.setup(opts)
	if state.enabled then return end
	opts = opts or {}
	M.config = vim.tbl_extend("force", M.config, opts)
	if not opts.repo_root then return end
	state.repo_root = opts.repo_root
	state.enabled = true

	local group = vim.api.nvim_create_augroup("HunkSigns", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "FocusGained" }, {
		group = group,
		callback = function(ev) debounced_refresh(ev.buf) end,
	})

	vim.api.nvim_create_user_command("HunkSignsRefresh", function()
		M.refresh()
	end, {})
	vim.api.nvim_create_user_command("HunkSignsToggleLinehl", function()
		M.toggle_linehl()
	end, {})

	-- ]h / [h navigate hunk-to-hunk in the current file. Set globally;
	-- gitsigns' buffer-local mapping wins where it attaches (proart), so
	-- ours only fires in buffers gitsigns doesn't reach (sandbox).
	vim.keymap.set("n", "]h", function() M.next_hunk() end, { desc = "Next hunk (hunk-signs)" })
	vim.keymap.set("n", "[h", function() M.prev_hunk() end, { desc = "Prev hunk (hunk-signs)" })

	debounced_refresh(vim.api.nvim_get_current_buf())
end

return M
