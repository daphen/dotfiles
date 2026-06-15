return {
	{
		"render-markdown.nvim",
		-- .mdx filetype is registered eagerly in init.lua (the ft trigger
		-- below can't fire on a filetype that doesn't exist yet).
		ft = { "mdx" },
		after = function()
			require("render-markdown").setup({ file_types = { "mdx" } })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "mdx",
				callback = function()
					vim.opt_local.conceallevel = 2
					vim.opt_local.concealcursor = ""
				end,
			})
		end,
	},
}
