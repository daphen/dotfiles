return {
	"f-person/auto-dark-mode.nvim",
	lazy = false,
	priority = 1001, -- Higher than colorscheme
	opts = {
		update_interval = 1000,
		set_dark_mode = function()
			vim.api.nvim_set_option_value("background", "dark", {})
			-- Just trigger a reload to pick up dark colors
			require("theme").reload()
		end,
		set_light_mode = function()
			vim.api.nvim_set_option_value("background", "light", {})
			-- Just trigger a reload to pick up light colors
			require("theme").reload()
		end,
	},
}
