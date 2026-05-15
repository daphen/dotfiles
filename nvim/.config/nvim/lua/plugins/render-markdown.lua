return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	ft = { "mdx" },
	init = function()
		-- Force .mdx files into their own filetype so render-markdown can
		-- target them without fighting markview on plain markdown.
		vim.filetype.add({
			extension = {
				mdx = "mdx",
			},
		})
	end,
	config = function()
		require("render-markdown").setup({
			file_types = { "mdx" },
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "mdx",
			callback = function()
				vim.opt_local.conceallevel = 2
				vim.opt_local.concealcursor = ""
			end,
		})
	end,
}
