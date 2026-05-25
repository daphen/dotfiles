--[[
hunk-nvim/follow — mirror hunk's selected file + hunk back into nvim.

Hunk's session API has no reverse event stream, so we poll `hunk session
review --output json` every poll_ms and check whether selectedFile.path or
selectedHunk.newRange[0] changed. When they do, open the file in the
current window and move the cursor.

Feedback-loop guard: nvim → hunk navigations call M.notify_navigation()
which stamps a timestamp. Polls within grace_ms of that stamp are ignored.
]]

local M = {}

M.config = {
	poll_ms = 300,
	grace_ms = 600,
	hunk_bin = "hunk",
}

local state = {
	enabled = false,
	repo_root = nil,
	timer = nil,
	last_file = nil,
	last_line = nil,
	last_nav_at = 0,
}

local function poll()
	if not state.enabled then return end
	if (vim.uv.now() - state.last_nav_at) < M.config.grace_ms then return end

	local out = vim.fn.system({
		M.config.hunk_bin, "session", "review",
		"--repo", state.repo_root,
		"--output", "json",
	})
	if vim.v.shell_error ~= 0 then return end
	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" or not data.review then return end

	local selected = data.review.selectedFile
	if not selected or not selected.path then return end
	local path = selected.path
	local hunk = data.review.selectedHunk
	local line = (hunk and hunk.newRange and hunk.newRange[1]) or 1

	if state.last_file == path and state.last_line == line then return end
	state.last_file = path
	state.last_line = line

	local abs = state.repo_root .. "/" .. path
	vim.schedule(function()
		local cur_abs = vim.api.nvim_buf_get_name(0)
		if cur_abs ~= abs then
			if vim.fn.filereadable(abs) == 1 then
				vim.cmd("edit " .. vim.fn.fnameescape(abs))
			else
				return
			end
		end
		local lc = vim.api.nvim_buf_line_count(0)
		local target = math.max(1, math.min(line, lc))
		vim.api.nvim_win_set_cursor(0, { target, 0 })
		vim.cmd("normal! zz")
	end)
end

function M.notify_navigation()
	state.last_nav_at = vim.uv.now()
end

function M.stop()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end
	state.enabled = false
end

function M.setup(opts)
	if state.enabled then return end
	opts = opts or {}
	M.config = vim.tbl_extend("force", M.config, opts)
	if not opts.repo_root then return end
	state.repo_root = opts.repo_root
	state.enabled = true

	state.timer = vim.uv.new_timer()
	state.timer:start(M.config.poll_ms, M.config.poll_ms, vim.schedule_wrap(poll))

	vim.api.nvim_create_user_command("HunkFollowStop", function() M.stop() end, {})
end

return M
