return {
	{
		dir = vim.fn.expand("~/.config/nvim/lua/theme"),
		name = "custom-theme",
		lazy = false,
		priority = 1000,
		config = function()
			local is_dark = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):match("Dark") ~= nil
			vim.o.background = is_dark and "dark" or "light"
			vim.cmd.colorscheme("custom-theme")

			-- Additional highlight overrides
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
