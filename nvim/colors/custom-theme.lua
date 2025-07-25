-- Custom Theme Colorscheme
-- This makes the theme available as a proper Neovim colorscheme

-- Clear existing highlights and set colorscheme name
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "custom-theme"

-- Load our custom theme
require("theme").setup()