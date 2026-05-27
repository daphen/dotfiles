--[[
hunk-nvim/signs — inline diff overlay in nvim buffers driven by git diff
against the Lovable init commit (the `[skip lovable] Initialize Lovable
project` commit), independent of hunk's daemon entirely.

- Signs in the gutter: │ for add/change, _ for delete-below, ‾ for topdelete
- Whole-line linehl: green for adds, red-ish for changes (toggle: <C-g>o)
- virt_lines: ghost lines showing the deleted content right where it was
  removed, so deletions are visible inline (toggle: :HunkSignsToggleDeleted)
- ]h / [h: walk between hunks
- Self-gates on git repo + reachable base commit

Works even in the sandbox's broken/shallow history because we only need
two endpoints (base and working tree), no history traversal.
]]

local M = {}

M.config = {
	-- Default to signs-only (gutter + virt_lines for deletions). Whole-line
	-- bg tint can be turned on per-session with :HunkSignsToggleLinehl or
	-- permanently via vim.g.hunk_signs_linehl = true in user config.
	linehl = false,
	deleted_virt_lines = true,
	debounce_ms = 200,
}

local NS = vim.api.nvim_create_namespace("hunk-signs")

local state = {
	enabled = false,
	repo_root = nil,
	base_sha = nil,
	debounce_timers = {},
}

local function git_exec(args)
	local out = vim.fn.systemlist(args)
	if vim.v.shell_error ~= 0 then return nil end
	return out
end

-- Source-agnostic base resolution. Priority:
--   1. Explicit override via HUNK_SIGNS_BASE env var or vim.g.hunk_signs_base
--   2. Lovable user-project init commit (only when it's a true root — its
--      [skip lovable] subject appears in test fixtures inside the monorepo
--      itself, so we guard on parent-count to avoid false positives)
--   3. merge-base with auto-detected trunk (origin/HEAD → main → master)
--   4. HEAD — gitsigns-like "uncommitted changes only" as a last resort
--
-- Exposed as M.resolve_base so other callers (e.g. the snacks picker) can
-- use the same base and stay in sync with the inline overlay.
function M.resolve_base(repo_root)
	repo_root = repo_root or state.repo_root
	if not repo_root then
		local out = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
		if vim.v.shell_error ~= 0 or #out == 0 then return nil end
		repo_root = out[1]
	end

	-- 1. Explicit override
	local override = vim.g.hunk_signs_base
	if override and override ~= "" then return override end
	local env = vim.fn.getenv("HUNK_SIGNS_BASE")
	if env and env ~= vim.NIL and env ~= "" then return env end

	-- 2. LoL true-root init commit. Search HEAD's ancestry only (no --all)
	-- so orphan LoL init commits fetched from other sandboxes into the
	-- monorepo don't masquerade as this branch's root.
	local lines = git_exec({
		"git", "-C", repo_root, "log",
		"--grep=\\[skip lovable\\] Initialize Lovable project", "--format=%H", "HEAD",
	})
	if lines and #lines > 0 then
		local candidate = lines[#lines]
		local parents = git_exec({
			"git", "-C", repo_root, "rev-parse", candidate .. "^@",
		})
		if not parents or #parents == 0 then return candidate end
	end

	-- 3. Branch fork point
	local trunk
	local origin_head = git_exec({
		"git", "-C", repo_root,
		"symbolic-ref", "--short", "refs/remotes/origin/HEAD",
	})
	if origin_head and #origin_head > 0 then trunk = origin_head[1] end
	if not trunk then
		for _, candidate in ipairs({ "main", "master", "origin/main", "origin/master" }) do
			if git_exec({ "git", "-C", repo_root, "rev-parse", "--verify", "--quiet", candidate }) then
				trunk = candidate
				break
			end
		end
	end
	if trunk then
		local mb = git_exec({ "git", "-C", repo_root, "merge-base", "HEAD", trunk })
		if mb and #mb > 0 then return mb[1] end
	end

	-- 4. Fall back to HEAD (gitsigns-like uncommitted-only view)
	return "HEAD"
end

local function fetch_diff(relpath)
	if not state.base_sha then return nil end
	local lines = vim.fn.systemlist({
		"git", "-C", state.repo_root, "diff", "--no-color",
		state.base_sha, "--", relpath,
	})
	if vim.v.shell_error ~= 0 then return nil end
	return table.concat(lines, "\n")
end

-- Parse a unified diff patch. Returns:
--   marks   = {[new_line_n] = "add"|"change"|"delete_below"|"topdelete"}
--   deletes = {[new_line_n] = {"deleted line content", ...}}
local function parse_patch(patch)
	local marks, deletes = {}, {}
	if not patch or patch == "" then return marks, deletes end
	local current_new = nil
	local pending = {}

	local function flush_pending()
		if #pending == 0 then return end
		local prev = (current_new or 1) - 1
		if prev >= 1 then
			if marks[prev] == nil then marks[prev] = "delete_below" end
			deletes[prev] = pending
		else
			marks[current_new] = "topdelete"
			deletes[current_new] = pending
		end
		pending = {}
	end

	for line in (patch .. "\n"):gmatch("([^\n]*)\n") do
		local n_start = line:match("^@@ %-%d+,?%d* %+(%d+)")
		if n_start then
			flush_pending()
			current_new = tonumber(n_start)
			pending = {}
		elseif current_new then
			local first = line:sub(1, 1)
			if first == "+" and line:sub(1, 3) ~= "+++" then
				if #pending > 0 then
					marks[current_new] = "change"
					table.remove(pending, 1)
				else
					marks[current_new] = marks[current_new] or "add"
				end
				current_new = current_new + 1
			elseif first == "-" and line:sub(1, 3) ~= "---" then
				table.insert(pending, line:sub(2))
			elseif first == " " or first == "" then
				flush_pending()
				current_new = current_new + 1
			end
		end
	end
	flush_pending()
	return marks, deletes
end

local function kind_to_sign(kind)
	if kind == "add" then return "│", "GitSignsAdd" end
	if kind == "change" then return "│", "GitSignsChange" end
	if kind == "delete_below" then return "_", "GitSignsDelete" end
	if kind == "topdelete" then return "‾", "GitSignsDelete" end
end

local function kind_to_linehl(kind)
	if kind == "add" then return "GitSignsAddLn" end
	if kind == "change" then return "GitSignsChangeLn" end
end

local function draw(bufnr, marks, deletes)
	vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	for ln, kind in pairs(marks) do
		if ln >= 1 and ln <= line_count then
			local sign, sign_hl = kind_to_sign(kind)
			local opts = {
				sign_text = sign,
				sign_hl_group = sign_hl,
				line_hl_group = M.config.linehl and kind_to_linehl(kind) or nil,
				invalidate = true,
			}
			if M.config.deleted_virt_lines and deletes[ln] and #deletes[ln] > 0 then
				local virt = {}
				for _, dl in ipairs(deletes[ln]) do
					table.insert(virt, { { dl, "GitSignsDeleteLn" } })
				end
				opts.virt_lines = virt
				opts.virt_lines_above = (kind == "topdelete")
			end
			pcall(vim.api.nvim_buf_set_extmark, bufnr, NS, ln - 1, 0, opts)
		end
	end
end

local function buf_relpath(bufnr)
	local abs = vim.api.nvim_buf_get_name(bufnr)
	if abs == "" or not state.repo_root then return nil end
	local prefix = state.repo_root .. "/"
	if abs:sub(1, #prefix) ~= prefix then return nil end
	return abs:sub(#prefix + 1)
end

function M.refresh(bufnr)
	if not state.enabled then return end
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_loaded(bufnr) then return end
	local relpath = buf_relpath(bufnr)
	if not relpath then return end
	local patch = fetch_diff(relpath)
	if not patch then
		vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
		return
	end
	local marks, deletes = parse_patch(patch)
	draw(bufnr, marks, deletes)
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
	local starts, last = {}, nil
	for _, ln in ipairs(lines) do
		if last == nil or ln > last + 1 then table.insert(starts, ln) end
		last = ln
	end
	return starts
end

function M.next_hunk()
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local starts = get_hunk_starts(vim.api.nvim_get_current_buf())
	for _, ln in ipairs(starts) do
		if ln > cur then vim.api.nvim_win_set_cursor(0, { ln, 0 }); return end
	end
	if #starts > 0 then vim.api.nvim_win_set_cursor(0, { starts[1], 0 }) end
end

function M.prev_hunk()
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local starts = get_hunk_starts(vim.api.nvim_get_current_buf())
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

function M.toggle_deleted()
	M.config.deleted_virt_lines = not M.config.deleted_virt_lines
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then M.refresh(bufnr) end
	end
end

function M.setup(opts)
	if state.enabled then return end
	opts = opts or {}
	-- vim.g.hunk_signs_linehl / hunk_signs_deleted let users override defaults
	-- without passing opts (handy when our config dir is read-only / managed).
	if vim.g.hunk_signs_linehl ~= nil then opts.linehl = vim.g.hunk_signs_linehl end
	if vim.g.hunk_signs_deleted ~= nil then opts.deleted_virt_lines = vim.g.hunk_signs_deleted end
	M.config = vim.tbl_extend("force", M.config, opts)

	local out = git_exec({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
	if not out or #out == 0 then return end
	state.repo_root = out[1]

	state.base_sha = M.resolve_base(state.repo_root)
	if not state.base_sha then return end
	state.enabled = true

	local group = vim.api.nvim_create_augroup("HunkSigns", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "FocusGained" }, {
		group = group,
		callback = function(ev) debounced_refresh(ev.buf) end,
	})

	vim.api.nvim_create_user_command("HunkSignsRefresh", function() M.refresh() end, {})
	vim.api.nvim_create_user_command("HunkSignsToggleLinehl", function() M.toggle_linehl() end, {})
	vim.api.nvim_create_user_command("HunkSignsToggleDeleted", function() M.toggle_deleted() end, {})

	vim.keymap.set("n", "]h", function() M.next_hunk() end, { desc = "Next hunk (git-signs)" })
	vim.keymap.set("n", "[h", function() M.prev_hunk() end, { desc = "Prev hunk (git-signs)" })

	debounced_refresh(vim.api.nvim_get_current_buf())
end

return M
