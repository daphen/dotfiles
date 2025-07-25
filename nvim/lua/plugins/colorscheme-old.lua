return {
	dir = vim.fn.expand("~/.config/colorscheme"),
	lazy = false,
	priority = 1000,
	config = function()
		require("rose-pine").setup({
			disable_background = true,
			disable_float_background = true,
			dark_variant = "main",
			highlight_groups = {
				StatusLine = { bg = "none" },
				StatusLineNC = { bg = "none" },
			},
			styles = {
				bold = true,
				italic = false,
				transparent = false,
			},
		})
		-- Fix quickfix list highlighting to match colorscheme
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				-- Only run if rose-pine is actually loaded
				if vim.g.colors_name ~= "rose-pine" then return end

				-- Get colors from the current colorscheme with proper fallbacks
				local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
				local visual_hl = vim.api.nvim_get_hl(0, { name = "Visual" })
				local keyword_hl = vim.api.nvim_get_hl(0, { name = "Keyword" })

				local fg = normal_hl.fg or 0xe0def4
				local selection = visual_hl.bg or 0x2a283e
				local accent = keyword_hl.fg or 0xc4a7e7

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
