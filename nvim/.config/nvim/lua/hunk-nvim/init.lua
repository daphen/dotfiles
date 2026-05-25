--[[
hunk-nvim — drive a running `hunk diff --watch` TUI from nvim's cursor.

`hunk session navigate --new-line <n>` accepts an absolute line number on
the new side; hunk resolves the hunk index server-side. So we don't have
to mirror its diff state — we just forward cursor line and let hunk do
the math.

- Gated on HUNK_NVIM_ENABLE so it's a true no-op locally on proart.
- detect_session uses `hunk session list --json` to verify a hunk TUI is
  open for this repo (avoids brittle plain-text substring matching).
- on_cursor (CursorMoved + BufEnter, debounced 200ms) fires off
  `hunk session navigate --new-line N` async. Fire-and-forget; we never
  read hunk's response.
- last_navigated dedup so cursor jitter on the same line doesn't spam.
- One-way: nvim drives, hunk follows. Hunk's API has no reverse stream.
]]

local M = {}

M.config = {
	enable_env = "HUNK_NVIM_ENABLE",
	debounce_ms = 200,
	hunk_bin = "hunk",
}

local state = {
	repo_root = nil,
	debounce_timer = nil,
	last_navigated = nil,
	enabled = false,
}

local function get_repo_root()
	local out = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
	if vim.v.shell_error ~= 0 then return nil end
	return (out:gsub("\n$", ""))
end

local function relative_to_repo(abs)
	if not state.repo_root or abs == "" then return nil end
	local prefix = state.repo_root .. "/"
	if abs:sub(1, #prefix) == prefix then return abs:sub(#prefix + 1) end
	return nil
end

-- Is hunk currently running a session for our repo? Uses --json to avoid
-- brittle substring matching against the human-readable list output.
local function detect_session()
	if not state.repo_root then return false end
	local out = vim.fn.system({ M.config.hunk_bin, "session", "list", "--json" })
	if vim.v.shell_error ~= 0 then return false end
	local ok, data = pcall(vim.json.decode, out)
	if not ok or type(data) ~= "table" then return false end
	for _, s in ipairs(data.sessions or {}) do
		if s.repoRoot == state.repo_root then return true end
	end
	return false
end

local function navigate(relpath, line)
	vim.system({
		M.config.hunk_bin, "session", "navigate",
		"--repo", state.repo_root,
		"--file", relpath,
		"--new-line", tostring(line),
	}, { text = true })
end

local function on_cursor()
	if not state.enabled then return end
	if state.debounce_timer then state.debounce_timer:stop() end
	state.debounce_timer = vim.defer_fn(function()
		state.debounce_timer = nil
		local relpath = relative_to_repo(vim.api.nvim_buf_get_name(0))
		if not relpath then return end
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local key = relpath .. ":" .. line
		if key == state.last_navigated then return end
		state.last_navigated = key
		navigate(relpath, line)
	end, M.config.debounce_ms)
end

local function attach_autocmds()
	local group = vim.api.nvim_create_augroup("HunkNvim", { clear = true })
	vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
		group = group,
		callback = on_cursor,
	})
end

local function try_attach()
	if not detect_session() then return false end
	state.enabled = true
	attach_autocmds()
	return true
end

function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	local v = vim.fn.getenv(M.config.enable_env)
	if v == vim.NIL or v == "" or v == "0" then return end

	state.repo_root = get_repo_root()
	if not state.repo_root then return end

	vim.api.nvim_create_user_command("HunkNvimStatus", function()
		print(vim.inspect({
			enabled = state.enabled,
			repo_root = state.repo_root,
			last_navigated = state.last_navigated,
		}))
	end, {})

	vim.api.nvim_create_user_command("HunkNvimRedetect", function()
		if try_attach() then
			print("hunk-nvim: attached")
		else
			print("hunk-nvim: no hunk session for " .. (state.repo_root or "?"))
		end
	end, {})

	if try_attach() then return end

	-- Hunk isn't running yet. Retry once when the user actually opens
	-- a file, so starting hunk after nvim still lights us up.
	vim.api.nvim_create_autocmd("BufEnter", {
		once = true,
		callback = function() try_attach() end,
	})
end

return M
