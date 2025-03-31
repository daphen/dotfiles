return {
	dir = vim.fn.expand("~/.config/colorscheme"),
	lazy = false,
	priority = 1000,
	config = function()
		require("rose-pine").setup({
			disable_background = true,
			disable_float_background = true,
			styles = {
				bold = true,
				italic = false,
				transparent = false,
			},
		})
		-- Fix quickfix list highlighting to match colorscheme
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "*",
			callback = function()
				-- Get colors from the current colorscheme
				local fg = vim.api.nvim_get_hl(0, { name = "Normal" }).fg or "#e0def4"
				local selection = vim.api.nvim_get_hl(0, { name = "Visual" }).bg or "#2a283e"
				local accent = vim.api.nvim_get_hl(0, { name = "Keyword" }).fg or "#c4a7e7"

				-- Set quickfix list highlights to match colorscheme
				vim.api.nvim_set_hl(0, "QuickFixLine", { bg = selection, bold = true })
				vim.api.nvim_set_hl(0, "qfFileName", { fg = fg, bold = true })

				-- Set search highlight to be more subtle
				vim.api.nvim_set_hl(0, "Search", { bg = selection, fg = accent, bold = true })
				vim.api.nvim_set_hl(0, "IncSearch", { bg = selection, fg = accent, bold = true, underline = true })
				vim.api.nvim_set_hl(0, "CurSearch", { bg = selection, fg = accent, bold = true, underline = true })
			end,
		})

		-- Trigger the colorscheme event to apply highlights immediately
		vim.cmd.colorscheme("rose-pine")
		vim.cmd("doautocmd ColorScheme")
	end,
}
