-- Per-buffer fs_event + on-demand git inbox. No recursive watching —
-- TS LSP / formatters generate enough FS churn to cause event storms.

local M = {}
local uv = vim.loop or vim.uv

local state = {
	watchers = {},
	debouncers = {},
	follow = true,
	base_cache = {},
	last_skip = nil,
	last_user_move = 0,
	snapshots = {},
	debug = false,
}

local function resolve_base_cached(repo)
	-- Keyed on HEAD so a git pull / branch switch invalidates the cache.
	local head = vim.fn.systemlist({ "git", "-C", repo, "rev-parse", "HEAD" })[1]
	local cached = state.base_cache[repo]
	if cached and cached.head == head then return cached.base end
	local base = require("hunk-nvim.signs").resolve_base(repo)
	if base then state.base_cache[repo] = { base = base, head = head } end
	return base
end
M.resolve_base_cached = resolve_base_cached

function M.clear_base_cache()
	state.base_cache = {}
	vim.notify("ai-tracker: base cache cleared")
end

local function first_changed_line(repo_root, base, relpath)
	local out = vim.fn.systemlist({ "git", "-C", repo_root, "diff", base, "--", relpath })
	if vim.v.shell_error ~= 0 then return nil end
	for _, line in ipairs(out) do
		local n = line:match("^@@ %-%d+,?%d* %+(%d+)")
		if n then return tonumber(n) end
	end
	return nil
end

local function compute_and_update_snapshot(path)
	local ok, current = pcall(vim.fn.readfile, path)
	if not ok then
		state.snapshots[path] = nil
		return nil
	end
	local prev = state.snapshots[path]
	state.snapshots[path] = current
	if not prev then return nil end
	local n = math.max(#prev, #current)
	for i = 1, n do
		if prev[i] ~= current[i] then return i end
	end
	return nil
end

local function pick_target_window()
	local function is_normal(w)
		local cfg = vim.api.nvim_win_get_config(w)
		if cfg.relative ~= "" then return false end
		return vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
	end
	local cur = vim.api.nvim_get_current_win()
	if is_normal(cur) then return cur end
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if is_normal(w) then return w end
	end
	return cur
end

local function repo_of(path)
	if not path or path == "" then return nil end
	local dir = vim.fn.fnamemodify(path, ":h")
	local r = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
	if not r or r == "" then return nil end
	return r
end

-- Tooling-generated paths we never auto-navigate to.
local IGNORED_PATTERNS = {
	"%.tsbuildinfo$",
	"%.log$",
	"%.lock$",
	"^pnpm%-lock%.yaml$",
	"^yarn%.lock$",
	"^package%-lock%.json$",
	"%.min%.js$",
	"%.min%.css$",
	"/dist/",
	"/build/",
	"/%.next/",
	"/coverage/",
	"%.snap$",
}

local function should_skip(path)
	for _, pat in ipairs(IGNORED_PATTERNS) do
		if path:match(pat) then return true end
	end
	return false
end

local function navigate_to_path(path, hint_line)
	if not state.follow then state.last_skip = "follow=OFF"; return end
	if should_skip(path) then state.last_skip = "ignored pattern"; return end
	if vim.api.nvim_get_mode().mode ~= "n" then
		state.last_skip = "mode=" .. vim.api.nvim_get_mode().mode
		return
	end
	if (vim.loop.now() - state.last_user_move) < 800 then
		state.last_skip = "user-active"
		return
	end
	if not path or path == "" then state.last_skip = "empty path"; return end
	local changed_repo = repo_of(path)
	if not changed_repo then state.last_skip = "no repo for " .. path; return end
	local cur_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
	local current_repo = repo_of(cur_name) or repo_of(vim.fn.getcwd() .. "/anything")
	if changed_repo ~= current_repo then
		state.last_skip = "repo mismatch"
		return
	end
	state.last_skip = nil
	if state.debug then vim.notify("ai-tracker → " .. path) end
	local target = pick_target_window()
	pcall(vim.api.nvim_set_current_win, target)
	pcall(vim.cmd, "edit " .. vim.fn.fnameescape(path))
	local line = hint_line
	if not line then
		local base = resolve_base_cached(changed_repo)
		if base then
			local relpath = path:sub(#changed_repo + 2)
			line = first_changed_line(changed_repo, base, relpath)
		end
	end
	line = line or 1
	pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
	pcall(vim.cmd, "normal! zz")
end

local function fire(bufnr)
	if state.debouncers[bufnr] then state.debouncers[bufnr]:stop() end
	state.debouncers[bufnr] = vim.defer_fn(function()
		state.debouncers[bufnr] = nil
		if not vim.api.nvim_buf_is_valid(bufnr) then return end
		pcall(vim.api.nvim_buf_call, bufnr, function() vim.cmd("checktime") end)
		pcall(function() require("hunk-nvim.signs").refresh(bufnr) end)
		local path = vim.api.nvim_buf_get_name(bufnr)
		if path == "" then return end
		local line = compute_and_update_snapshot(path)
		navigate_to_path(path, line)
	end, 50)
end

local function watchable(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then return false end
	if vim.bo[bufnr].buftype ~= "" then return false end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then return false end
	local stat = uv.fs_stat(name)
	return stat ~= nil and stat.type == "file"
end

local function detach(bufnr)
	local w = state.watchers[bufnr]
	if w then
		pcall(function() w:stop() end)
		pcall(function() w:close() end)
		state.watchers[bufnr] = nil
	end
	local d = state.debouncers[bufnr]
	if d then d:stop() end
	state.debouncers[bufnr] = nil
end

local function attach(bufnr)
	if state.watchers[bufnr] then return end
	if not watchable(bufnr) then return end
	local path = uv.fs_realpath(vim.api.nvim_buf_get_name(bufnr)) or vim.api.nvim_buf_get_name(bufnr)
	local w = uv.new_fs_event()
	if not w then return end
	state.watchers[bufnr] = w
	local function on_event(err)
		if err then return end
		vim.schedule(function() fire(bufnr) end)
		pcall(function() w:stop() end)
		vim.schedule(function()
			if state.watchers[bufnr] == w and vim.api.nvim_buf_is_valid(bufnr) then
				pcall(function() w:start(path, {}, on_event) end)
			end
		end)
	end
	if not pcall(function() w:start(path, {}, on_event) end) then detach(bufnr) end
end

local function scan_all_buffers()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do attach(bufnr) end
end

function M.setup()
	require("ai-tracker.session").setup()
	require("ai-tracker.git_status").setup()
	local group = vim.api.nvim_create_augroup("AITracker", { clear = true })
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost" }, {
		group = group,
		callback = function(ev) attach(ev.buf) end,
	})
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		group = group,
		callback = function(ev) detach(ev.buf) end,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter" }, {
		group = group,
		callback = function() state.last_user_move = vim.loop.now() end,
	})
	scan_all_buffers()
	if vim.v.vim_did_enter == 1 then
		vim.schedule(scan_all_buffers)
	else
		vim.api.nvim_create_autocmd("VimEnter", {
			group = group, once = true, callback = scan_all_buffers,
		})
	end

	vim.api.nvim_create_user_command("AITrackerInbox", function()
		require("ai-tracker.preview").open()
	end, {})
	vim.api.nvim_create_user_command("AITrackerRefresh", scan_all_buffers, {})
	vim.api.nvim_create_user_command("AITrackerStatus", function()
		local watching, watchable_count, total = 0, 0, 0
		for _ in pairs(state.watchers) do watching = watching + 1 end
		for _, b in ipairs(vim.api.nvim_list_bufs()) do
			total = total + 1
			if watchable(b) then watchable_count = watchable_count + 1 end
		end
		local msg = ("ai-tracker: %d buffer fs_events, %d/%d watchable buffers, follow=%s")
			:format(watching, watchable_count, total, state.follow and "ON" or "OFF")
		if state.last_skip then msg = msg .. "\n  last navigate skip: " .. state.last_skip end
		vim.notify(msg)
	end, {})
	vim.api.nvim_create_user_command("AITrackerFollow", function() M.toggle_follow() end, {})
	vim.api.nvim_create_user_command("AITrackerClearCache", function() M.clear_base_cache() end, {})
	vim.api.nvim_create_user_command("AITrackerDebug", function()
		state.debug = not state.debug
		vim.notify("ai-tracker debug " .. (state.debug and "ON" or "OFF"))
	end, {})
	vim.api.nvim_create_user_command("AITrackerTouched", function()
		local files = require("ai-tracker.session").touched_files()
		vim.cmd("new")
		vim.bo.buftype = "nofile"
		vim.bo.bufhidden = "wipe"
		vim.bo.filetype = "ai-tracker-touched"
		if #files == 0 then
			vim.api.nvim_buf_set_lines(0, 0, -1, false, { "(no touched files this session)" })
			return
		end
		local lines = {}
		for _, e in ipairs(files) do
			lines[#lines + 1] = ("%-8s %-26s %s"):format(e.tool, e.ts or "", e.path)
		end
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	end, {})
	vim.api.nvim_create_user_command("AITrackerRescan", function()
		require("ai-tracker.session").rescan()
		local s = require("ai-tracker.session").status()
		vim.notify(("ai-tracker.session: rescanned, %d touched files"):format(s.count))
	end, {})
	vim.api.nvim_create_user_command("AITrackerReattach", function()
		require("ai-tracker.session").reattach()
		local s = require("ai-tracker.session").status()
		vim.notify(("ai-tracker.session: dir=%s file=%s"):format(s.dir or "(none)", s.file or "(none)"))
	end, {})
	vim.api.nvim_create_user_command("AITrackerGitStatus", function()
		local s = require("ai-tracker.git_status").status()
		vim.notify(("ai-tracker.git_status\n  cwd:   %s\n  poll:  %dms\n  count: %d")
			:format(s.cwd or "(none)", s.poll_ms, s.count))
	end, {})
	vim.api.nvim_create_user_command("AITrackerGitTouched", function()
		local files = require("ai-tracker.git_status").touched_files()
		vim.cmd("new")
		vim.bo.buftype = "nofile"
		vim.bo.bufhidden = "wipe"
		vim.bo.filetype = "ai-tracker-touched"
		if #files == 0 then
			vim.api.nvim_buf_set_lines(0, 0, -1, false, { "(no files touched since session start)" })
			return
		end
		local lines = {}
		for _, e in ipairs(files) do
			lines[#lines + 1] = ("%s  %s  %s"):format(e.code or "  ", os.date("%H:%M:%S", e.ts), e.path)
		end
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	end, {})
	vim.api.nvim_create_user_command("AITrackerGitRebaseline", function()
		require("ai-tracker.git_status").rebaseline()
		vim.notify("ai-tracker.git_status: rebaselined — only future changes count")
	end, {})
	vim.api.nvim_create_user_command("AITrackerSessionStatus", function()
		local s = require("ai-tracker.session").status()
		vim.notify(("ai-tracker.session\n  dir:    %s\n  file:   %s\n  offset: %d\n  count:  %d")
			:format(s.dir or "(none)", s.file or "(none)", s.offset, s.count))
	end, {})
	vim.api.nvim_create_user_command("AITrackerDiagnose", function()
		local cwd = vim.fn.getcwd()
		local cur_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
		local repo = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })[1]
		print("cwd:        " .. cwd)
		print("cur_buf:    " .. (cur_name == "" and "(no name)" or cur_name))
		print("repo_root:  " .. (repo or "(nil)"))
		if not repo then return end
		local t0 = vim.loop.hrtime()
		local base = resolve_base_cached(repo)
		local elapsed = (vim.loop.hrtime() - t0) / 1e6
		print(("base:       %s  (resolve %dms)"):format(base or "(nil)", elapsed))
	end, {})
end

function M.show() require("ai-tracker.preview").open() end

function M.toggle_follow()
	state.follow = not state.follow
	vim.notify("ai-tracker: follow " .. (state.follow and "ON" or "OFF"))
end

return M
