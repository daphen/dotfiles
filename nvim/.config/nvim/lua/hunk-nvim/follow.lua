--[[
hunk-nvim/follow — sync nvim cursor + open file to hunk's current selection
when the nvim pane regains terminal focus.

Hunk emits no events, so we can't be reactive. But you can only ever
navigate in one pane at a time — by the time you come back to nvim,
whatever you did in hunk is "frozen" until next time you go there. So a
single `hunk session review` query on FocusGained captures everything
without polling.
]]

local M = {}

M.config = {
	hunk_bin = "hunk",
}

local state = {
	repo_root = nil,
	last_file = nil,
	last_line = nil,
}

local function fetch_selection()
	local out = vim.fn.system({
		M.config.hunk_bin, "session", "review",
		"--repo", state.repo_root,
		"--output", "json",
	})
	if vim.v.shell_error ~= 0 then return nil end
	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" or not data.review then return nil end
	return data.review
end

function M.sync_once()
	if not state.repo_root then return false end
	local review = fetch_selection()
	if not review then return false end
	local selected = review.selectedFile
	if not selected or not selected.path then return false end
	local path = selected.path
	local hunk = review.selectedHunk
	local line = (hunk and hunk.newRange and hunk.newRange[1]) or 1

	if state.last_file == path and state.last_line == line then return false end
	state.last_file = path
	state.last_line = line

	local abs = state.repo_root .. "/" .. path
	if vim.fn.filereadable(abs) ~= 1 then return false end
	local cur = vim.api.nvim_buf_get_name(0)
	if cur ~= abs then vim.cmd("edit " .. vim.fn.fnameescape(abs)) end
	local lc = vim.api.nvim_buf_line_count(0)
	local target = math.max(1, math.min(line, lc))
	vim.api.nvim_win_set_cursor(0, { target, 0 })
	vim.cmd("normal! zz")
	return true
end

function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_extend("force", M.config, opts)
	if not opts.repo_root then return end
	state.repo_root = opts.repo_root

	local group = vim.api.nvim_create_augroup("HunkFollow", { clear = true })
	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		callback = function() vim.schedule(function() M.sync_once() end) end,
	})

	vim.api.nvim_create_user_command("HunkFollowSync", function() M.sync_once() end, {})
end

return M
