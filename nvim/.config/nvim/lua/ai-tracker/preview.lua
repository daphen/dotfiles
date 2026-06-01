-- "What's changed" floating inbox. j/k nav, Enter open, q/Esc close.

local M = {}

local state = {
	list_buf = nil,
	preview_buf = nil,
	list_win = nil,
	preview_win = nil,
	prev_win = nil,
	files = {},
	cursor = 1,
	repo_root = nil,
	base = nil,
}

local function resolve_base(repo)
	-- Cached path avoids ~500ms git log --grep per open in a monorepo.
	local ok, tracker = pcall(require, "ai-tracker")
	if ok and tracker.resolve_base_cached then return tracker.resolve_base_cached(repo) end
	return require("hunk-nvim.signs").resolve_base(repo)
end

local function git_changed(repo_root, base)
	local files, seen = {}, {}
	local diff = vim.fn.systemlist({ "git", "-C", repo_root, "diff", "--name-status", base })
	if vim.v.shell_error == 0 then
		for _, line in ipairs(diff) do
			local status, path = line:match("^(%S+)%s+(.+)$")
			if status and path then
				table.insert(files, { status = status, path = path })
				seen[path] = true
			end
		end
	end
	-- git diff doesn't show untracked files; query them separately.
	local untracked = vim.fn.systemlist({
		"git", "-C", repo_root, "ls-files", "--others", "--exclude-standard",
	})
	if vim.v.shell_error == 0 then
		for _, path in ipairs(untracked) do
			if not seen[path] then
				table.insert(files, { status = "??", path = path })
				seen[path] = true
			end
		end
	end
	return files
end

local function git_diff_for(repo_root, base, path, status)
	if status == "??" then
		-- Untracked: git diff has nothing to show, fall back to file contents.
		local ok, lines = pcall(vim.fn.readfile, repo_root .. "/" .. path)
		if ok then return lines end
		return { "(untracked: " .. path .. ")" }
	end
	local out = vim.fn.systemlist({ "git", "-C", repo_root, "diff", base, "--", path })
	if vim.v.shell_error ~= 0 then return { "(error reading diff)" } end
	return out
end

local function set_lines(buf, lines)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

local function render_list()
	if #state.files == 0 then
		set_lines(state.list_buf, { "(no changes vs base " .. (state.base or "?"):sub(1, 7) .. ")" })
		return
	end
	local lines = {}
	for _, f in ipairs(state.files) do
		table.insert(lines, string.format(" %s  %s", f.status, f.path))
	end
	set_lines(state.list_buf, lines)
	pcall(vim.api.nvim_win_set_cursor, state.list_win, { state.cursor, 0 })
end

local function render_preview()
	if #state.files == 0 then
		set_lines(state.preview_buf, { "(nothing to preview)" })
		return
	end
	local f = state.files[state.cursor]
	if not f then return end
	set_lines(state.preview_buf, git_diff_for(state.repo_root, state.base, f.path, f.status))
	vim.bo[state.preview_buf].filetype = (f.status == "??") and "" or "diff"
end

local function close()
	for _, w in ipairs({ state.list_win, state.preview_win }) do
		if w and vim.api.nvim_win_is_valid(w) then pcall(vim.api.nvim_win_close, w, true) end
	end
	state.list_win, state.preview_win = nil, nil
end

local function on_select()
	local f = state.files[state.cursor]
	if not f then return end
	local full = state.repo_root .. "/" .. f.path
	close()
	if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
		vim.api.nvim_set_current_win(state.prev_win)
	end
	vim.cmd("edit " .. vim.fn.fnameescape(full))
end

local function move(delta)
	if #state.files == 0 then return end
	state.cursor = math.max(1, math.min(#state.files, state.cursor + delta))
	pcall(vim.api.nvim_win_set_cursor, state.list_win, { state.cursor, 0 })
	render_preview()
end

local function keymaps(buf)
	local o = { buffer = buf, nowait = true, silent = true }
	vim.keymap.set("n", "j", function() move(1) end, o)
	vim.keymap.set("n", "k", function() move(-1) end, o)
	vim.keymap.set("n", "<Down>", function() move(1) end, o)
	vim.keymap.set("n", "<Up>", function() move(-1) end, o)
	vim.keymap.set("n", "<CR>", on_select, o)
	vim.keymap.set("n", "q", close, o)
	vim.keymap.set("n", "<Esc>", close, o)
end

local function scratch()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	return buf
end

function M.open()
	state.prev_win = vim.api.nvim_get_current_win()
	local toplevel = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })[1]
	if not toplevel or toplevel == "" then
		vim.notify("ai-tracker: not in a git repo", vim.log.levels.WARN)
		return
	end
	state.repo_root = toplevel
	state.base = resolve_base(toplevel)
	if not state.base then
		vim.notify("ai-tracker: could not resolve base", vim.log.levels.WARN)
		return
	end
	state.files = git_changed(toplevel, state.base)
	-- Recently-touched files first.
	local uv = vim.loop or vim.uv
	for _, f in ipairs(state.files) do
		local st = uv.fs_stat(toplevel .. "/" .. f.path)
		f._mtime = st and (st.mtime.sec * 1000 + math.floor((st.mtime.nsec or 0) / 1e6)) or 0
	end
	table.sort(state.files, function(a, b) return a._mtime > b._mtime end)
	state.cursor = 1

	local W, H = vim.o.columns, vim.o.lines
	local w = math.floor(W * 0.9)
	local h = math.floor(H * 0.8)
	local row = math.floor((H - h) / 2)
	local col = math.floor((W - w) / 2)
	local lw = math.floor(w * 0.35)
	local pw = w - lw - 1

	state.list_buf = scratch()
	state.preview_buf = scratch()

	state.list_win = vim.api.nvim_open_win(state.list_buf, true, {
		relative = "editor", row = row, col = col, width = lw, height = h,
		border = "rounded",
		title = " Changed files (vs " .. state.base:sub(1, 7) .. ") ",
		title_pos = "center",
	})
	state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
		relative = "editor", row = row, col = col + lw + 1, width = pw, height = h,
		border = "rounded",
		title = " Diff ", title_pos = "center",
	})

	vim.wo[state.list_win].cursorline = true
	vim.wo[state.list_win].number = false
	vim.wo[state.preview_win].number = false
	vim.wo[state.preview_win].wrap = false

	keymaps(state.list_buf)
	render_list()
	render_preview()

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = state.list_buf,
		callback = function()
			local r = vim.api.nvim_win_get_cursor(state.list_win)[1]
			if r ~= state.cursor and #state.files > 0 then
				state.cursor = r
				render_preview()
			end
		end,
	})
end

return M
