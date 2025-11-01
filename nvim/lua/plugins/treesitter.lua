return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/playground",
		},
		config = function()
			-- First set up the basic TreeSitter configuration without the keymaps
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "javascript", "typescript", "lua" },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<CR>",
						scope_incremental = "<CR>",
						node_incremental = "<TAB>",
						node_decremental = "<BS>",
					},
				},
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				playground = {
					enable = true,
				},
				textobjects = {
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["}}"] = "@function.outer",
						},
						goto_previous_start = {
							["{{"] = "@function.outer",
						},
					},
				},
			})

		-- Add keymapping for TreeSitter playground
		vim.keymap.set("n", "<leader>T", ":TSPlaygroundToggle<CR>", { desc = "Toggle TreeSitter playground" })
		end,
	},
}
