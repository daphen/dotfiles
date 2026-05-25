--[[
hunk-nvim — drive a running `hunk diff --watch` TUI from neovim's cursor.

Design:
- Gated behind the HUNK_NVIM_ENABLE env var. Locally on proart we don't
  want this active (no hunk session running, no agent we're reviewing).
  In a LoL sandbox, daphen-env sets the var when launching the shell, so
  it lights up automatically there.
- On CursorMoved / BufEnter, debounce ~200ms, then locate the hunk under
  the cursor and shell out to `hunk session navigate`. Fire-and-forget;
  navigate is unidirectional so we don't wait on the response.
- `hunk session review --json` is cached for a few seconds and refreshed
  on BufWritePost so the hunk indices stay accurate after local edits.
- No reverse direction (hunk → nvim). The hunk session API is one-way;
  if the user navigates inside the hunk TUI, nvim doesn't follow. That's
  acceptable for the "nvim drives, hunk mirrors" workflow.
]]

local M = {}

M.config = {
  enable_env = "HUNK_NVIM_ENABLE",
  debounce_ms = 200,
  cache_ttl_ms = 5000,
  hunk_bin = "hunk",
}

local state = {
  repo_root = nil,
  review_cache = nil,
  review_cache_ts = 0,
  debounce_timer = nil,
  last_navigated = nil,
  enabled = false,
}

local function get_repo_root(path)
  local cwd = path or vim.fn.getcwd()
  local out = vim.fn.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then return nil end
  return (out:gsub("\n$", ""))
end

-- Fetch hunk's view of the current changeset. Cached so we don't shell
-- out on every cursor move; invalidated on BufWritePost.
local function refresh_review(force)
  if not state.repo_root then return nil end
  local now = vim.uv.now()
  if not force and state.review_cache and (now - state.review_cache_ts) < M.config.cache_ttl_ms then
    return state.review_cache
  end
  local out = vim.fn.system({
    M.config.hunk_bin, "session", "review",
    "--repo", state.repo_root,
    "--json",
  })
  if vim.v.shell_error ~= 0 then
    state.review_cache = nil
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, out)
  if not ok then return nil end
  state.review_cache = decoded
  state.review_cache_ts = now
  return decoded
end

-- Given the review payload, find the 1-based hunk index in `relpath`
-- whose new-side line range contains `line`. Returns nil if the file
-- isn't tracked by the current hunk session or the line is between
-- hunks.
local function locate_hunk(review, relpath, line)
  if not review or not review.files then return nil end
  for _, f in ipairs(review.files) do
    if f.path == relpath then
      for i, h in ipairs(f.hunks or {}) do
        local start = h.new_start or h.start_line
        local count = h.new_count or h.line_count or 0
        if start and line >= start and line < start + count then
          return i
        end
      end
      return nil
    end
  end
  return nil
end

local function navigate(relpath, idx)
  vim.system({
    M.config.hunk_bin, "session", "navigate",
    "--repo", state.repo_root,
    "--file", relpath,
    "--hunk", tostring(idx),
  }, { text = true })
end

local function relative_to_repo(abs)
  if not state.repo_root or abs == "" then return nil end
  local prefix = state.repo_root .. "/"
  if abs:sub(1, #prefix) == prefix then return abs:sub(#prefix + 1) end
  return nil
end

local function on_cursor()
  if not state.enabled then return end
  if state.debounce_timer then state.debounce_timer:stop() end
  state.debounce_timer = vim.defer_fn(function()
    state.debounce_timer = nil
    local abs = vim.api.nvim_buf_get_name(0)
    local relpath = relative_to_repo(abs)
    if not relpath then return end
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local review = refresh_review(false)
    local idx = locate_hunk(review, relpath, line)
    if not idx then return end
    local key = relpath .. ":" .. idx
    if key == state.last_navigated then return end
    state.last_navigated = key
    navigate(relpath, idx)
  end, M.config.debounce_ms)
end

local function detect_session()
  local out = vim.fn.system({ M.config.hunk_bin, "session", "list" })
  if vim.v.shell_error ~= 0 then return false end
  return out:find(state.repo_root, 1, true) ~= nil
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  local v = vim.fn.getenv(M.config.enable_env)
  if v == vim.NIL or v == "" or v == "0" then return end

  state.repo_root = get_repo_root()
  if not state.repo_root then return end

  state.enabled = detect_session()
  if not state.enabled then
    -- Hunk isn't running yet; retry on first BufEnter so the user can
    -- start hunk after nvim and have things light up.
    vim.api.nvim_create_autocmd("BufEnter", {
      once = true,
      callback = function()
        state.enabled = detect_session()
        if state.enabled then M.setup(opts) end
      end,
    })
    return
  end

  local group = vim.api.nvim_create_augroup("HunkNvim", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "BufEnter" }, {
    group = group,
    callback = on_cursor,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function() refresh_review(true) end,
  })

  vim.api.nvim_create_user_command("HunkNvimStatus", function()
    print(vim.inspect({
      enabled = state.enabled,
      repo_root = state.repo_root,
      cache_age_ms = state.review_cache and (vim.uv.now() - state.review_cache_ts) or "n/a",
      cached_files = state.review_cache and #(state.review_cache.files or {}) or 0,
      last_navigated = state.last_navigated,
    }))
  end, {})

  vim.api.nvim_create_user_command("HunkNvimRefresh", function()
    refresh_review(true)
    print("hunk-nvim: review cache refreshed")
  end, {})
end

return M
