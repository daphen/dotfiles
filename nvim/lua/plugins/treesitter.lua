return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/playground",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "javascript", "typescript", "lua" },
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				playground = {
					enable = true,
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]]"] = "@function.outer",
							["}}"] = "@block.inner",
						},
						goto_previous_start = {
							["[["] = "@function.outer",
							["{{"] = "@block.inner",
						},
					},
				},
			})

			-- Add keymapping for TreeSitter playground
			vim.keymap.set("n", "<leader>tp", ":TSPlaygroundToggle<CR>", { desc = "Toggle TreeSitter playground" })
		end,
	},
}
