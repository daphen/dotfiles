return {
	"OXY2DEV/markview.nvim",
	lazy = false,
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("markview").setup({
			-- Your custom configuration here if needed
		})

		-- Set conceallevel for markdown files specifically
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function()
				vim.opt_local.conceallevel = 2
				vim.opt_local.concealcursor = ""
			end,
		})
	end,
}
