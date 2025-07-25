return {
	-- Keep rose-pine for now as backup
	{
		dir = vim.fn.expand("~/.config/colorscheme"),
		lazy = false,
		priority = 1000,
		enabled = false, -- Disable for now
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
		end,
	},
	-- Our new custom theme
	{
		dir = vim.fn.expand("~/.config/nvim/lua/theme"),
		name = "custom-theme",
		lazy = false,
		priority = 1000,
		config = function()
			-- Apply the colorscheme
			vim.cmd.colorscheme("custom-theme")
			
			-- Additional highlight overrides if needed
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "custom-theme",
				callback = function()
					-- Transparent backgrounds
					vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
					vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
					vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
					vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
				end,
			})
		end,
	},
}