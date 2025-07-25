return {
	"Chaitanyabsprip/fastaction.nvim",
	config = function()
		require("fastaction").setup({
			keys = "asdfghlzxcvbnm",
			popup = {
				border = "rounded",
				hide_cursor = true,
				highlight = {
					divider = "FloatBorder",
					key = "MoreMsg",
					title = "Title",
					window = "NormalFloat",
				},
				title = "Select one of:", -- or false to disable title
			},
		})

		vim.keymap.set({ "n", "x" }, "<leader>ca", '<cmd>lua require("fastaction").code_action()<CR>')
	end,
}
