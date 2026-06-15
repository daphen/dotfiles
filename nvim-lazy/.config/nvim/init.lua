local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Disable netrw so mini.files handles directory args + <CR> on dir entries.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Hijack directory buffers and hand them to mini.files. Registered here
-- (not inside mini.nvim's config) so the autocmd exists before VimEnter
-- fires — otherwise the initial directory buffer slips through.
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		local path = vim.fn.expand(args.match)
		if path == "" then return end
		local stat = vim.loop.fs_stat(path)
		if not stat or stat.type ~= "directory" then return end
		vim.schedule(function()
			vim.cmd("bdelete!")
			-- Loading mini.files triggers lazy.nvim → runs mini.lua's
			-- config, which exposes _mini_files_setup. Call it so the
			-- custom window dimensions apply.
			local mini_files = require("mini.files")
			if _G._mini_files_setup then _G._mini_files_setup() end
			mini_files.open(path)
		end)
	end,
})

require("keymaps")
require("options")
require("notes-sync")

require("lazy").setup("plugins")
