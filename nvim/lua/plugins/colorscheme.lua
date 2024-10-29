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
		vim.cmd.colorscheme("rose-pine")
	end,
}
