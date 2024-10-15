local opt = vim.opt

-- line number
opt.relativenumber = true
opt.number = true

opt.scrolloff = 8

-- tabs & indent
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.wrap = false

-- Sync clipboard between OS and Neovim.
opt.clipboard = "unnamedplus"

opt.ignorecase = true
opt.smartcase = true

vim.opt.undofile = true

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Color options
opt.termguicolors = true
opt.background = "dark"
opt.fillchars = { eob = " " }

opt.backspace = "indent,eol,start"

-- Move cursor to the perceived new split when opening it
opt.splitright = true
opt.splitbelow = true

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
