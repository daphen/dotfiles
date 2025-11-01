---@class AITracker
local M = {}

local utils = require("ai-tracker.utils")
local picker = require("ai-tracker.picker")

-- Configuration
M.config = {
  log_file = vim.fn.expand("~/.local/share/nvim/ai-changes.jsonl"),
  max_entries = 1000, -- Maximum entries to keep in memory
  auto_reload = true, -- Auto-reload changes when showing picker
}

-- State
M.state = {
  changes = {}, -- Cached changes
  last_read = 0, -- Last time we read the log file
  pending_prompt = nil, -- For manual annotation mode
  pending_count = 0, -- How many writes to track for pending prompt
  notified_files = {}, -- Files we've already notified about in this session
}

--- Setup the plugin
---@param opts? table Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Ensure log directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(M.config.log_file, ":h"), "p")

  -- Setup sign definitions for AI changes
  M.setup_signs()

  -- Setup autocmds for manual tracking (fallback mode)
  M.setup_autocmds()

  -- Setup user commands
  M.setup_commands()
  
  -- Setup buffer signs on enter
  M.setup_buffer_signs()
  
  -- Apply highlights to the initial buffer
  vim.defer_fn(function()
    M.update_buffer_signs()
    M.check_and_notify_changes()
  end, 100)
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

--- Setup buffer line number highlights on BufEnter
function M.setup_buffer_signs()
  local group = vim.api.nvim_create_augroup("AITrackerHighlights", { clear = true })
  
  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufWritePost", "ColorScheme" }, {
    group = group,
    callback = function()
      -- Re-setup highlights on ColorScheme change
      if vim.v.event and vim.v.event.event == "ColorScheme" then
        M.setup_signs()
      end
      M.update_buffer_signs()
      
      -- Check for AI changes and notify/show picker if needed  
      if vim.v.event and vim.v.event.event == "BufEnter" or vim.v.event.event == "BufReadPost" then
        M.check_and_notify_changes()
      end
    end,
  })
end

--- Check for AI changes and notify user
function M.check_and_notify_changes()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    return
  end
  
  -- Only check if we haven't notified about this file recently
  M.state.notified_files = M.state.notified_files or {}
  if M.state.notified_files[current_file] then
    return
  end
  
  -- Get changes for this file only
  local changes = M.get_changes()
  local file_changes = {}
  local lines = {}
  
  for _, change in ipairs(changes) do
    if change.file_path == current_file then
      table.insert(file_changes, change)
      lines[change.line_number or 1] = true
    end
  end
  
  -- Notify if there are AI changes in this file
  if #file_changes > 0 then
    local line_list = vim.tbl_keys(lines)
    table.sort(line_list)
    
    -- Format line ranges for compact display
    local ranges = {}
    local i = 1
    while i <= #line_list do
      local start = line_list[i]
      local finish = start
      
      -- Find consecutive lines
      while i < #line_list and line_list[i + 1] == finish + 1 do
        i = i + 1
        finish = line_list[i]
      end
      
      if start == finish then
        table.insert(ranges, tostring(start))
      else
        table.insert(ranges, string.format("%d-%d", start, finish))
      end
      i = i + 1
    end
    
    vim.notify(
      string.format("AI modified lines: %s", table.concat(ranges, ", ")),
      vim.log.levels.INFO,
      { title = "AI Tracker" }
    )
    
    -- Mark as notified for this session
    M.state.notified_files[current_file] = true
  end
end

--- Update line number highlights for current buffer
function M.update_buffer_signs()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.fn.expand("%:p")
  
  if file_path == "" then
    return
  end
  
  -- Create namespace for our highlights
  local ns_id = vim.api.nvim_create_namespace("ai_tracker_lines")
  
  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  -- Get changes for this file
  local changes = M.get_changes()
  local file_changes = {}
  local seen_lines = {}
  
  for _, change in ipairs(changes) do
    if change.file_path == file_path then
      local line = change.line_number or 1
      if not seen_lines[line] then
        seen_lines[line] = true
        table.insert(file_changes, change)
      end
    end
  end
  
  -- Add line number highlights for AI changes
  local now = os.time()
  for _, change in ipairs(file_changes) do
    local line = change.line_number or 1

    -- Check if change is recent (within last 24 hours)
    local is_recent = false
    if change.timestamp then
      -- Parse ISO timestamp properly
      local year, month, day, hour, min, sec = change.timestamp:match(
        "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
      )
      if year then
        local change_time = os.time({
          year = tonumber(year) or 2024,
          month = tonumber(month) or 1,
          day = tonumber(day) or 1,
          hour = tonumber(hour) or 0,
          min = tonumber(min) or 0,
          sec = tonumber(sec) or 0,
        })
        is_recent = (now - change_time) < 86400 -- 24 hours
      end
    end

    local hl_group = is_recent and "AITrackerRecentLineNr" or "AITrackerLineNr"

    -- Calculate the number of lines in this change block
    local start_line = line - 1 -- 0-based for extmarks
    local line_count = utils.count_lines(change.new_string or "") or 1
    local end_line = start_line + line_count

    -- Set extmarks to highlight line numbers for the entire block
    for current_line = start_line, math.min(end_line - 1, vim.api.nvim_buf_line_count(bufnr) - 1) do
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, current_line, 0, {
        number_hl_group = hl_group,
        priority = 100, -- Lower than signs but visible
      })
    end
  end
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

--- Find changes in current file
---@return table[] Array of changes for current file
function M.get_file_changes()
  local current_file = vim.fn.expand("%:p")
  local changes = M.get_changes()
  local file_changes = {}

  for _, change in ipairs(changes) do
    if change.file_path == current_file then
      table.insert(file_changes, change)
    end
  end

  -- Sort by line number
  table.sort(file_changes, function(a, b)
    return a.line_number < b.line_number
  end)

  return file_changes
end

--- Jump to next AI change in current file
function M.next()
  local file_changes = M.get_file_changes()
  if #file_changes == 0 then
    vim.notify("No AI changes found in current file", vim.log.levels.INFO)
    return
  end

  local current_line = vim.fn.line(".")

  -- Find next change after current line
  for _, change in ipairs(file_changes) do
    if change.line_number > current_line then
      vim.fn.cursor(change.line_number, 1)
      vim.cmd("normal! zz")
      -- Only show prompt in a subtle way as virtual text, not notification
      M.highlight_change(change)
      return
    end
  end

  -- Wrap to first change
  if #file_changes > 0 then
    vim.fn.cursor(file_changes[1].line_number, 1)
    vim.cmd("normal! zz")
    M.highlight_change(file_changes[1])
  end
end

--- Jump to previous AI change in current file
function M.prev()
  local file_changes = M.get_file_changes()
  if #file_changes == 0 then
    vim.notify("No AI changes found in current file", vim.log.levels.INFO)
    return
  end

  local current_line = vim.fn.line(".")

  -- Find previous change before current line (iterate in reverse)
  for i = #file_changes, 1, -1 do
    local change = file_changes[i]
    if change.line_number < current_line then
      vim.fn.cursor(change.line_number, 1)
      vim.cmd("normal! zz")
      M.highlight_change(change)
      return
    end
  end

  -- Wrap to last change
  if #file_changes > 0 then
    local last_change = file_changes[#file_changes]
    vim.fn.cursor(last_change.line_number, 1)
    vim.cmd("normal! zz")
    M.highlight_change(last_change)
  end
end

--- Highlight a change temporarily when navigating
---@param change table Change entry
function M.highlight_change(change)
  local ns_id = vim.api.nvim_create_namespace("ai_tracker_highlight")
  local bufnr = vim.api.nvim_get_current_buf()

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Calculate line range
  local start_line = change.line_number - 1
  local end_line = start_line + (utils.count_lines(change.new_string or "") or 1)

  -- Briefly highlight the changed lines with a subtle background
  for line = start_line, math.min(end_line, vim.api.nvim_buf_line_count(bufnr) - 1) do
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Visual", line, 0, -1)
  end

  -- Clear highlight after 2 seconds
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    end
  end, 2000)
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
        M.state.notified_files = {}
        M.update_buffer_signs()
        vim.notify("AI Tracker: Reset for new feature", vim.log.levels.INFO)
      end
    end
  end)
end

return M
