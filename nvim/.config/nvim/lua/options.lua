local opt = vim.opt

-- line number
opt.relativenumber = true
opt.number = true

opt.scrolloff = 5
opt.sidescrolloff = 15

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

-- Cursor settings
-- Set cursor to blink in all modes while preserving terminal colors
opt.guicursor = "n-c-sm:block-blinkon400-blinkoff250," .. "i-ci:ver25," .. "v-ve:hor20," .. "r-cr-o:hor20"

-- Highlight when yanking (copying) text and sync to primary selection
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking and sync to primary selection",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ timeout = 150 })
		-- Also copy to primary selection for middle-click paste
		if vim.v.event.operator == "y" then
			local content = vim.fn.getreg('"')
			vim.fn.jobstart({ "wl-copy", "--primary", content }, { detach = true })
		end
	end,
})

-- Color options
opt.termguicolors = true
opt.fillchars = {
	horiz = "━",
	horizup = "┻",
	horizdown = "┳",
	vert = "┃",
	vertleft = "┫",
	vertright = "┣",
	verthoriz = "╋",
	eob = " ",
}

opt.backspace = "indent,eol,start"

-- Move cursor to the perceived new split when opening it
opt.splitright = true
opt.splitbelow = true

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

opt.showcmd = false
opt.laststatus = 3 -- Global statusline

-- Swap file settings
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.updatetime = 300

-- Auto-reload files when changed externally
opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	pattern = "*",
	command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None",
})

-- Fix AltGr (Right Alt) behavior for Swedish characters
-- Prevent Alt from exiting insert mode when using AltGr combos
opt.timeout = true
opt.timeoutlen = 500
opt.ttimeoutlen = 10
