-- Custom Theme
-- A minimal, maintainable colorscheme integrated with centralized theme system

local M = {}

-- Load colors from generated file
local ok, colors = pcall(require, "theme.colors")
if not ok then
  vim.notify("Failed to load theme colors", vim.log.levels.ERROR)
  return M
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  
  -- Set colorscheme name if not already set
  if not vim.g.colors_name then
    vim.g.colors_name = "custom-theme"
  end
  
  -- Debug: log which theme we're loading
  local theme_colors = colors.get_colors()
  vim.notify("Loading theme: " .. vim.o.background .. " mode", vim.log.levels.INFO)
  
  -- Load and apply highlights
  local highlights = require("theme.highlights")
  highlights.setup(theme_colors)
end

-- Helper to reload the colorscheme
function M.reload()
  package.loaded["theme.colors"] = nil
  package.loaded["theme.highlights"] = nil
  package.loaded["theme"] = nil
  require("theme").setup()
end

-- Command to reload colorscheme
vim.api.nvim_create_user_command("ReloadTheme", function()
  M.reload()
  vim.notify("Theme reloaded", vim.log.levels.INFO)
end, {})

return M