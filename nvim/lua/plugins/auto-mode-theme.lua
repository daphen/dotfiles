return {
	"f-person/auto-dark-mode.nvim",
	opts = {
		update_interval = 1000,
		set_dark_mode = function()
			vim.api.nvim_set_option_value("background", "dark", {})
			-- Check which colorscheme we're using
			if vim.g.colors_name == "custom-theme" then
				-- Just trigger a reload to pick up dark colors
				require("theme").reload()
			else
				-- Fallback to rose-pine
				require("rose-pine").setup({
					disable_background = true,
					disable_float_background = true,
					variant = "main",
					dark_variant = "main",
				})
				vim.cmd("colorscheme rose-pine")
			end
		end,
		set_light_mode = function()
			vim.api.nvim_set_option_value("background", "light", {})
			-- Check which colorscheme we're using
			if vim.g.colors_name == "custom-theme" then
				-- Just trigger a reload to pick up light colors
				require("theme").reload()
			else
				-- Fallback to rose-pine
				require("rose-pine").setup({
					disable_background = true,
					disable_float_background = true,
					variant = "dawn",
					dark_variant = "main",
				})
				vim.cmd("colorscheme rose-pine")
			end
		end,
	},
}
