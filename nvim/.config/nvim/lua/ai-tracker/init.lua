---@class AITracker
local M = {}

local utils = require("ai-tracker.utils")
local picker = require("ai-tracker.picker")
local watcher = require("ai-tracker.watcher")

-- Configuration
M.config = {
  log_file = vim.fn.expand("~/.local/share/nvim/ai-changes.jsonl"),
  max_entries = 1000,
  auto_reload = true,
  watch = {
    enabled = true,
    debounce_ms = 150,
    poll_fallback_ms = 5000,
  },
  notify = {
    -- "single" = one popup per flush, "silent" = no popup (autocmd still fires)
    mode = "single",
    flush_ms = 300,
  },
  auto_reload_buffers = true, -- checktime affected buffers when AI writes land
  -- When true, switch the current window to the file an AI just edited (only
  -- if the file is in this nvim's project). Skipped while in insert mode so
  -- it doesn't yank the buffer out from under live typing.
  live_follow = true,
  preview = {
    -- Live diff preview for Claude Code Edit/Write/MultiEdit. When enabled,
    -- the PreToolUse hook (preview-hook.py) blocks until you accept/reject
    -- the diff in nvim. Run :AITrackerPreviewInstall for the settings.json
    -- snippet to wire up.
    enabled = true,
  },
}

--- Resolve a strict project root from a directory. Requires either a git repo
--- or a project marker — bare cwd is rejected so e.g. opening nvim in $HOME
--- doesn't end up matching every AI edit on the machine.
---@param dir string
---@return string?
local function resolve_strict_project_root(dir)
  if not dir or dir == "" then return nil end

  local git_root = vim.fn.system(
    "git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null"
  ):gsub("\n", "")
  if vim.v.shell_error == 0 and git_root ~= "" then
    return git_root
  end

  local markers = { "package.json", "tsconfig.json", "Cargo.toml", "pyproject.toml", "go.mod" }
  local path = dir
  while path and #path > 1 do
    for _, marker in ipairs(markers) do
      local candidate = path .. "/" .. marker
      if vim.fn.filereadable(candidate) ~= 0 or vim.fn.isdirectory(candidate) ~= 0 then
        return path
      end
    end
    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path or parent == "" then break end
    path = parent
  end
  return nil
end

-- Memoize project root by cwd so we don't shell out to git for every edit.
local _project_root_cache = { cwd = nil, root = nil }
local function current_project_root()
  local cwd = vim.fn.getcwd()
  if _project_root_cache.cwd ~= cwd then
    _project_root_cache.cwd = cwd
    _project_root_cache.root = resolve_strict_project_root(cwd)
  end
  return _project_root_cache.root
end

local function path_in_current_project(path)
  local root = current_project_root()
  return root ~= nil and path ~= nil and vim.startswith(path, root)
end

local function in_insert_mode()
  return vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
end

-- State
M.state = {
  changes = {}, -- Cached changes
  last_read = 0,
  pending_prompt = nil,
  pending_count = 0,
  -- Per-file session state. Keyed by absolute path.
  -- { first_opened_at, last_seen_at, unread_count, unread_lines, last_ai_write_at }
  files = {},
  -- Queue of background edits waiting to be notified.
  notify_queue = {}, -- array of { path, count }
  notify_timer = nil,
}

--- Setup the plugin
---@param opts? table Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.fn.mkdir(vim.fn.fnamemodify(M.config.log_file, ":h"), "p")

  M.setup_signs()
  M.setup_autocmds()
  M.setup_commands()
  M.setup_buffer_hooks()

  if M.config.watch.enabled then
    watcher.start({
      path = M.config.log_file,
      debounce_ms = M.config.watch.debounce_ms,
      poll_fallback_ms = M.config.watch.poll_fallback_ms,
      on_batch = function(entries) M.handle_batch(entries) end,
    })
  end

  if M.config.preview.enabled then
    require("ai-tracker.preview").start()
  end

  -- Auto-switch to the most recent AI edit on startup. Deferred so that
  -- session-restoration plugins finish first.
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      vim.defer_fn(function() M.on_vim_enter() end, 100)
    end,
  })
end

--- Setup highlight groups for line numbers
function M.setup_signs()
  -- Try to get colors from the theme system
  local theme_ok, theme_colors = pcall(require, "theme.colors")
  local colors = {}
  
  if theme_ok and theme_colors then
    -- Get current theme colors (dark or light based on vim.o.background)
    local theme = vim.o.background == "light" and "light" or "dark"
    colors = theme_colors.colors[theme]
  else
    -- Fallback colors if theme not loaded
    colors = {
      orange = "#FF570D",
      yellow = "#ff8a31",
    }
  end
  
  -- Define custom highlight groups for AI tracker line numbers
  -- Use orange (cursor color) for all AI-modified lines
  vim.api.nvim_set_hl(0, "AITrackerLineNr", { 
    fg = colors.orange or "#FF570D",
    bold = true 
  })
  
  -- Recent changes can use a slightly different shade (yellow/gold)
  vim.api.nvim_set_hl(0, "AITrackerRecentLineNr", { 
    fg = colors.yellow or colors.orange or "#ff8a31",
    bold = true 
  })
end

--- Setup BufEnter/ColorScheme hooks.
--- BufEnter marks a file as "opened this session" and clears its unread state.
function M.setup_buffer_hooks()
  local group = vim.api.nvim_create_augroup("AITrackerHooks", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    group = group,
    callback = function(ev)
      local path = vim.api.nvim_buf_get_name(ev.buf)
      if path == "" then return end
      path = vim.fn.fnamemodify(path, ":p")
      M.mark_opened(path, ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      M.setup_signs()
      -- Re-render unread highlights on the current buffer with new colors.
      M.update_buffer_signs(vim.api.nvim_get_current_buf())
    end,
  })
end

--- Mark a file as opened in this session. Clears unread state and its highlights.
---@param path string Absolute file path
---@param bufnr integer Buffer number
function M.mark_opened(path, bufnr)
  local fstate = M.state.files[path]
  if not fstate then
    fstate = { first_opened_at = os.time() }
    M.state.files[path] = fstate
  end
  fstate.last_seen_at = os.time()

  if fstate.unread_count and fstate.unread_count > 0 then
    fstate.unread_count = 0
    fstate.unread_lines = nil
    M.update_buffer_signs(bufnr)
  end
end

--- Render unread-line highlights for a buffer.
--- Only highlights lines that were edited by the AI after the user first opened
--- this file and has not yet revisited. Clears on BufEnter (see mark_opened).
---@param bufnr? integer
function M.update_buffer_signs(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then return end
  path = vim.fn.fnamemodify(path, ":p")

  local ns_id = vim.api.nvim_create_namespace("ai_tracker_lines")
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local fstate = M.state.files[path]
  if not fstate or not fstate.unread_lines or #fstate.unread_lines == 0 then return end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local seen = {}
  for _, line in ipairs(fstate.unread_lines) do
    local row = (tonumber(line) or 1) - 1
    if row >= 0 and row < line_count and not seen[row] then
      seen[row] = true
      pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, row, 0, {
        number_hl_group = "AITrackerRecentLineNr",
        priority = 100,
      })
    end
  end
end

--- Reload in-memory cache and handle a batch of newly-appended log entries.
--- This is the main dispatcher wired to the watcher.
---@param entries table[]
function M.handle_batch(entries)
  -- Append to cache so pickers reflect live state.
  for _, e in ipairs(entries) do
    table.insert(M.state.changes, 1, e)
  end

  -- Group by file; one decision + one notification per file per batch.
  local by_file = {}
  for _, e in ipairs(entries) do
    local path = e.file_path
    if path and path ~= "" then
      by_file[path] = by_file[path] or {}
      table.insert(by_file[path], e)
    end
  end

  local current_buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")

  for path, file_entries in pairs(by_file) do
    local bufnr = vim.fn.bufnr(path)
    local loaded = bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr)

    -- Reload the buffer if it's loaded, so gitsigns + the rest of the world see fresh content.
    if loaded and M.config.auto_reload_buffers then
      M.safe_checktime(bufnr)
    end

    local fstate = M.state.files[path]
    local is_background = fstate and fstate.first_opened_at and path ~= current_buf_path

    if is_background then
      fstate.unread_count = (fstate.unread_count or 0) + #file_entries
      fstate.unread_lines = fstate.unread_lines or {}
      fstate.last_ai_write_at = os.time()
      for _, e in ipairs(file_entries) do
        table.insert(fstate.unread_lines, e.line_number or 1)
      end

      -- If the affected buffer is loaded, draw the unread highlights.
      if loaded then M.update_buffer_signs(bufnr) end

      M.notify_enqueue(path, #file_entries)
    end
  end

  -- Live-follow: switch the current window to the latest AI edit in this
  -- project so the user can watch the AI work in real time. Insert mode is a
  -- hard veto so we never clobber a buffer the user is actively typing in.
  if M.config.live_follow and not in_insert_mode() then
    local follow
    for _, e in ipairs(entries) do
      if e.file_path and path_in_current_project(e.file_path) then
        if not follow or (e.timestamp or "") > (follow.timestamp or "") then
          follow = e
        end
      end
    end
    if follow and vim.fn.filereadable(follow.file_path) ~= 0 then
      local cur = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
      if cur ~= follow.file_path then
        pcall(vim.cmd, "edit " .. vim.fn.fnameescape(follow.file_path))
      end
      if follow.line_number then
        pcall(vim.fn.cursor, follow.line_number, 1)
        pcall(vim.cmd, "normal! zz")
      end
    end
  end
end

--- Reload a buffer from disk, unless it has unsaved changes or is a special buftype.
---@param bufnr integer
function M.safe_checktime(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].modified then return end
  if vim.bo[bufnr].buftype ~= "" then return end
  pcall(vim.api.nvim_buf_call, bufnr, function() vim.cmd("checktime") end)
end

--- Queue a background-edit notification; flushed on a debounce.
---@param path string
---@param count integer
function M.notify_enqueue(path, count)
  table.insert(M.state.notify_queue, { path = path, count = count })

  if M.state.notify_timer then
    M.state.notify_timer:stop()
  else
    M.state.notify_timer = (vim.uv or vim.loop).new_timer()
  end
  M.state.notify_timer:start(
    M.config.notify.flush_ms,
    0,
    vim.schedule_wrap(function() M.notify_flush() end)
  )
end

--- Flush queued notifications into a single summary.
function M.notify_flush()
  local queue = M.state.notify_queue
  M.state.notify_queue = {}
  if #queue == 0 then return end

  -- Coalesce per file.
  local per_file = {}
  local file_order = {}
  for _, item in ipairs(queue) do
    if not per_file[item.path] then
      per_file[item.path] = 0
      table.insert(file_order, item.path)
    end
    per_file[item.path] = per_file[item.path] + item.count
  end

  -- Emit a User autocmd so statuslines/lualine can react.
  pcall(vim.api.nvim_exec_autocmds, "User", {
    pattern = "AITrackerBackgroundEdit",
    data = { files = per_file },
  })

  if M.config.notify.mode == "silent" then return end

  local parts = {}
  for _, path in ipairs(file_order) do
    local _, rel = utils.format_path(path)
    local name = rel ~= "" and rel or vim.fn.fnamemodify(path, ":t")
    table.insert(parts, string.format("%s (%d)", name, per_file[path]))
  end

  local total_files = #file_order
  local summary = string.format(
    "AI Tracker: %d background edit%s — %s",
    #queue,
    #queue == 1 and "" or "s",
    table.concat(parts, ", ")
  )
  if total_files > 3 then
    -- Cap the list so it doesn't blow past the message area.
    summary = string.format(
      "AI Tracker: %d background edits across %d files",
      #queue,
      total_files
    )
  end

  vim.notify(summary, vim.log.levels.INFO, { title = "AI Tracker" })
end

--- Find the most recent AI change whose file lives under the current project.
--- Returns nil if cwd is not inside an identifiable project — that's
--- intentional, so unrelated nvim sessions don't auto-switch.
---@return table? change entry or nil
function M.get_latest_in_project()
  local changes = M.get_changes()
  if #changes == 0 then return nil end

  local project_root = current_project_root()
  if not project_root then return nil end

  local latest
  for _, change in ipairs(changes) do
    local path = change.file_path
    if path and vim.startswith(path, project_root) then
      if not latest or (change.timestamp or "") > (latest.timestamp or "") then
        latest = change
      end
    end
  end

  if latest and vim.fn.filereadable(latest.file_path) == 0 then return nil end
  return latest
end

--- Jump to the most recently AI-edited file in the current project.
function M.jump_to_latest()
  local latest = M.get_latest_in_project()
  if not latest then
    vim.notify("AI Tracker: no recent AI edits in this project", vim.log.levels.INFO)
    return
  end

  local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  if current ~= latest.file_path then
    vim.cmd("edit " .. vim.fn.fnameescape(latest.file_path))
  end
  if latest.line_number then
    vim.fn.cursor(latest.line_number, 1)
    vim.cmd("normal! zz")
  end
end

--- Does the current buffer's file appear in the AI change log?
---@return boolean
local function current_file_is_ai_changed()
  local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  if current == "" then return false end
  for _, c in ipairs(M.get_changes()) do
    if c.file_path == current then return true end
  end
  return false
end

--- VimEnter handler — auto-switch to latest AI-edited file when it makes sense.
--- Rules:
---   - argc > 0 (explicit file args): notify only.
---   - current buffer is any AI-touched file: notify only.
---   - otherwise: switch.
function M.on_vim_enter()
  local latest = M.get_latest_in_project()
  if not latest then return end

  local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  local name = vim.fn.fnamemodify(latest.file_path, ":t")
  local line = latest.line_number or 1

  local notify_only = vim.fn.argc() > 0 or current_file_is_ai_changed()
  if notify_only then
    local msg
    if current == latest.file_path then
      msg = string.format("AI Tracker: latest edit is this file (line %d)", line)
    else
      msg = string.format("AI Tracker: latest edit — %s:%d (<C-f> to jump)", name, line)
    end
    vim.notify(msg, vim.log.levels.INFO, { title = "AI Tracker" })
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(latest.file_path))
  vim.fn.cursor(line, 1)
  vim.cmd("normal! zz")
end

--- Jump to the first unread AI-touched line in the current buffer.
function M.jump_to_unread()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  local fstate = M.state.files[path]
  if not fstate or not fstate.unread_lines or #fstate.unread_lines == 0 then
    vim.notify("AI Tracker: no unread changes in this buffer", vim.log.levels.INFO)
    return
  end
  local first = math.huge
  for _, l in ipairs(fstate.unread_lines) do
    if (tonumber(l) or math.huge) < first then first = tonumber(l) end
  end
  if first == math.huge then return end
  vim.fn.cursor(first, 1)
  vim.cmd("normal! zz")
end

--- Setup autocmds for manual file change tracking
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("AITracker", { clear = true })

  -- Track file writes when in manual annotation mode
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      if M.state.pending_prompt and M.state.pending_count > 0 then
        -- Log this change with the pending prompt
        M.log_manual_change(ev.file, M.state.pending_prompt)
        M.state.pending_count = M.state.pending_count - 1

        if M.state.pending_count <= 0 then
          vim.notify(
            string.format("AI Tracker: Finished tracking changes for prompt: %s", utils.truncate(M.state.pending_prompt, 50)),
            vim.log.levels.INFO
          )
          M.state.pending_prompt = nil
        end
      end
    end,
  })

  -- NOTE: Auto-clearing on git push is disabled
  -- Use <C-g>r to manually reset tracking when starting a new feature
  --
  -- -- Clear AI tracking after git push operations
  -- vim.api.nvim_create_autocmd("User", {
  --   pattern = "FugitiveChanged",
  --   group = group,
  --   callback = function()
  --     -- After fugitive git operations, check if we pushed
  --     vim.defer_fn(function()
  --       M.clear_after_push()
  --     end, 100)
  --   end,
  -- })
  --
  -- -- Check after shell commands that might be git push
  -- vim.api.nvim_create_autocmd("TermClose", {
  --   group = group,
  --   callback = function()
  --     local bufname = vim.api.nvim_buf_get_name(0)
  --     -- Check if this was a git command or lazygit
  --     if bufname:match("git") or bufname:match("lazygit") then
  --       vim.defer_fn(function()
  --         M.clear_after_push()
  --       end, 500)
  --     end
  --   end,
  -- })
  --
  -- -- Also check after :!git push commands
  -- vim.api.nvim_create_autocmd("ShellCmdPost", {
  --   group = group,
  --   callback = function()
  --     vim.defer_fn(function()
  --       M.clear_after_push()
  --     end, 100)
  --   end,
  -- })
end

--- Setup user commands
function M.setup_commands()
  vim.api.nvim_create_user_command("AITracker", function()
    M.show()
  end, { desc = "Show all AI changes" })

  vim.api.nvim_create_user_command("AITrackerFile", function()
    M.show_file()
  end, { desc = "Show AI changes for current file" })

  vim.api.nvim_create_user_command("AITrackerGrouped", function()
    M.show_grouped()
  end, { desc = "Show AI changes grouped by prompt" })

  vim.api.nvim_create_user_command("AITrackerSessions", function()
    M.show_sessions()
  end, { desc = "Show AI changes by session" })
  
  vim.api.nvim_create_user_command("AITrackerAllLines", function()
    M.show_all_lines()
  end, { desc = "Show all AI changes (individual lines)" })

  vim.api.nvim_create_user_command("AITrackerPromptFiles", function()
    M.show_prompt_files()
  end, { desc = "Show which files each prompt changed" })

  vim.api.nvim_create_user_command("AIPrompt", function(cmd)
    M.annotate_prompt(cmd.args)
  end, {
    nargs = "?",
    desc = "Annotate next file changes with AI prompt",
  })

  vim.api.nvim_create_user_command("AITrackerClear", function()
    M.clear_log()
  end, { desc = "Clear AI changes log" })
  
  vim.api.nvim_create_user_command("AITrackerClearCommitted", function()
    M.clear_committed_files()
  end, { desc = "Clear AI tracking for files in last commit" })
  
  vim.api.nvim_create_user_command("AITrackerClearClean", function()
    M.clear_clean_files()
  end, { desc = "Clear AI tracking for clean (non-modified) git files" })
  
  vim.api.nvim_create_user_command("AITrackerReset", function()
    M.reset_tracking()
  end, { desc = "Reset all AI tracking (start fresh for new feature)" })

  vim.api.nvim_create_user_command("AITrackerReload", function()
    M.reload_changes()
    vim.notify("AI Tracker: Reloaded changes", vim.log.levels.INFO)
  end, { desc = "Reload AI changes from log file" })

  vim.api.nvim_create_user_command("AITrackerUnread", function()
    M.jump_to_unread()
  end, { desc = "Jump to first unread AI edit in current buffer" })

  vim.api.nvim_create_user_command("AITrackerJumpLatest", function()
    M.jump_to_latest()
  end, { desc = "Jump to the most recent AI-edited file in this project" })

  vim.api.nvim_create_user_command("AITrackerPreviewInstall", function()
    local hook_path = require("ai-tracker.preview").hook_path()
    local snippet = vim.json.encode({
      hooks = {
        PreToolUse = {
          {
            matcher = "Edit|Write|MultiEdit",
            hooks = { { type = "command", command = hook_path } },
          },
        },
      },
    })
    -- Pretty-print
    local ok, decoded = pcall(vim.json.decode, snippet)
    if ok then snippet = vim.fn.json_encode(decoded) end
    local lines = {
      "Hook script: " .. hook_path,
      "",
      "Add this to ~/.claude/settings.json (merge with existing 'hooks' if present):",
      "",
      vim.inspect(decoded or {}),
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "AI Tracker — Preview Install" })
  end, { desc = "Show the settings.json snippet to enable preview hook" })
end

--- Read changes from log file
---@return table[] Array of change entries
function M.read_changes()
  return utils.read_jsonl(M.config.log_file)
end

--- Reload changes from log file
function M.reload_changes()
  M.state.changes = M.read_changes()
  M.state.last_read = os.time()
end

--- Get changes (with optional auto-reload)
---@return table[] Array of change entries
function M.get_changes()
  if M.config.auto_reload or #M.state.changes == 0 then
    M.reload_changes()
  end
  return M.state.changes
end

--- Log a manual change (fallback mode)
---@param file_path string File path
---@param prompt string AI prompt
function M.log_manual_change(file_path, prompt)
  local entry = {
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    source = "manual",
    tool = "unknown",
    file_path = vim.fn.fnamemodify(file_path, ":p"),
    line_number = 1, -- Unknown for manual tracking
    prompt = prompt,
    session_id = vim.fn.getpid(),
  }

  utils.append_jsonl(M.config.log_file, entry)

  -- Add to cache
  table.insert(M.state.changes, 1, entry)
end

--- Show AI changes in current project (grouped by file for performance)
function M.show()
  local changes = M.get_changes()
  
  -- Filter to current project (prioritize git root for monorepos)
  local current_file = vim.fn.expand("%:p")
  local project_root = nil
  
  local utils_ok, main_utils = pcall(require, "utils")
  if current_file ~= "" and utils_ok and main_utils and main_utils.get_project_root_git_priority then
    project_root = main_utils.get_project_root_git_priority(current_file)
  end
  
  -- If we found a project root, filter changes to this project
  local filtered_changes = changes
  if project_root then
    filtered_changes = {}
    for _, change in ipairs(changes) do
      if change.file_path and vim.startswith(change.file_path, project_root) then
        table.insert(filtered_changes, change)
      end
    end
  end
  
  picker.show(filtered_changes, { 
    title = project_root and "AI Changes (current project)" or "AI Changes (all)",
    group_by_file = true,
    limit = 100  -- Show recent 100 files
  })
end

--- Show all individual line changes (detailed view)
function M.show_all_lines()
  local changes = M.get_changes()
  picker.show(changes, { 
    title = "AI Changes (all lines)",
    group_by_file = false,
    limit = 200  -- Limit for performance
  })
end

--- Show AI changes for current file
function M.show_file()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  local changes = M.get_changes()
  picker.show(changes, {
    title = "AI Changes (current file)",
    filter_file = current_file,
    group_by_file = false,  -- Show individual lines for current file
  })
end

--- Show AI changes grouped by prompt
function M.show_grouped()
  local changes = M.get_changes()
  picker.show_grouped(changes)
end

--- Show AI changes by session
function M.show_sessions()
  local changes = M.get_changes()
  picker.show_sessions(changes)
end

--- Show files changed by a specific prompt
function M.show_prompt_files()
  local changes = M.get_changes()
  picker.show_prompt_files(changes)
end

--- Annotate next file changes with a prompt (manual mode)
---@param prompt? string AI prompt
function M.annotate_prompt(prompt)
  if not prompt or prompt == "" then
    vim.ui.input({ prompt = "AI Prompt: " }, function(input)
      if input and input ~= "" then
        M.start_annotation(input)
      end
    end)
  else
    M.start_annotation(prompt)
  end
end

--- Start annotation mode
---@param prompt string AI prompt
function M.start_annotation(prompt)
  M.state.pending_prompt = prompt
  M.state.pending_count = 999 -- Track unlimited changes until manually stopped

  vim.notify(
    string.format("AI Tracker: Tracking changes for prompt: %s\nUse :AIPrompt again to stop.", utils.truncate(prompt, 50)),
    vim.log.levels.INFO
  )
end

--- Clear the log file
function M.clear_log()
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Clear all AI changes history?",
  }, function(choice)
    if choice == "Yes" then
      local file = io.open(vim.fn.expand(M.config.log_file), "w")
      if file then
        file:close()
        M.state.changes = {}
        vim.notify("AI Tracker: Cleared all changes", vim.log.levels.INFO)
      end
    end
  end)
end

--- Clear AI tracking for specific files
---@param file_paths table List of file paths to clear
function M.clear_files(file_paths)
  if not file_paths or #file_paths == 0 then
    return
  end
  
  -- Create a set for faster lookup
  local files_to_clear = {}
  for _, path in ipairs(file_paths) do
    files_to_clear[vim.fn.expand(path)] = true
  end
  
  -- Read all changes
  local all_changes = M.read_changes()
  local kept_changes = {}
  local removed_count = 0
  
  -- Filter out changes for the specified files
  for _, change in ipairs(all_changes) do
    if not files_to_clear[change.file_path] then
      table.insert(kept_changes, change)
    else
      removed_count = removed_count + 1
    end
  end
  
  -- Rewrite the log file with kept changes
  if removed_count > 0 then
    local file = io.open(vim.fn.expand(M.config.log_file), "w")
    if file then
      for _, change in ipairs(kept_changes) do
        file:write(vim.json.encode(change) .. "\n")
      end
      file:close()
      
      -- Reload changes
      M.reload_changes()
      
      -- Update current buffer highlights
      M.update_buffer_signs()
      
      vim.notify(string.format("AI Tracker: Cleared %d changes from %d file(s)", 
        removed_count, vim.tbl_count(files_to_clear)), vim.log.levels.INFO)
    end
  end
end

--- Clear AI tracking for committed files
function M.clear_committed_files()
  -- Get list of files in the last commit
  local result = vim.fn.system("git diff --name-only HEAD~1 HEAD 2>/dev/null")
  
  if vim.v.shell_error == 0 and result ~= "" then
    local files = {}
    for file in result:gmatch("[^\r\n]+") do
      -- Convert relative paths to absolute
      local abs_path = vim.fn.fnamemodify(file, ":p")
      table.insert(files, abs_path)
    end
    
    if #files > 0 then
      M.clear_files(files)
    end
  end
end

--- Clear AI tracking for all clean (non-modified) files
function M.clear_clean_files()
  -- Get current git status
  local result = vim.fn.system("git status --porcelain 2>/dev/null")
  
  if vim.v.shell_error ~= 0 then
    return -- Not in a git repo
  end
  
  -- Parse modified files
  local modified_files = {}
  for line in result:gmatch("[^\r\n]+") do
    local file = line:match("^.. (.+)$")
    if file then
      modified_files[vim.fn.fnamemodify(file, ":p")] = true
    end
  end
  
  -- Get all AI-tracked files
  local all_changes = M.read_changes()
  local tracked_files = {}
  for _, change in ipairs(all_changes) do
    tracked_files[change.file_path] = true
  end
  
  -- Find clean files (tracked but not modified)
  local clean_files = {}
  for file_path, _ in pairs(tracked_files) do
    if not modified_files[file_path] then
      table.insert(clean_files, file_path)
    end
  end
  
  if #clean_files > 0 then
    M.clear_files(clean_files)
    vim.notify(string.format("AI Tracker: Cleared tracking for %d clean file(s)", #clean_files), vim.log.levels.INFO)
  end
end

--- Clear AI tracking after git push
function M.clear_after_push()
  -- Get the current branch
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
  
  if vim.v.shell_error ~= 0 or branch == "" then
    return -- Not in a git repo
  end
  
  -- Check if the branch has a remote tracking branch
  local remote = vim.fn.system(string.format("git config branch.%s.remote 2>/dev/null", branch)):gsub("\n", "")
  
  if remote == "" then
    return -- No remote configured
  end
  
  -- Get files that are in sync with remote (pushed)
  local result = vim.fn.system(string.format("git diff --name-only %s/%s..HEAD 2>/dev/null", remote, branch))
  
  if vim.v.shell_error == 0 and result == "" then
    -- No differences with remote, all changes are pushed
    -- Clear all AI tracking since everything is pushed
    M.clear_clean_files()
    vim.notify("AI Tracker: Cleared tracking for pushed files", vim.log.levels.INFO)
  end
end

--- Reset AI tracking (for starting new features)
function M.reset_tracking()
  vim.ui.select({ "Reset all AI tracking?", "Cancel" }, {
    prompt = "Start fresh for new feature:",
  }, function(choice)
    if choice == "Reset all AI tracking?" then
      local file = io.open(vim.fn.expand(M.config.log_file), "w")
      if file then
        file:close()
        M.state.changes = {}
        M.state.files = {}
        M.update_buffer_signs()
        vim.notify("AI Tracker: Reset for new feature", vim.log.levels.INFO)
      end
    end
  end)
end

return M
