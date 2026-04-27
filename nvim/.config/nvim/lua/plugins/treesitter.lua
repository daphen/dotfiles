return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			-- Standard nvim-treesitter master-branch config — paired with nvim 0.11.x
			-- (pinned in nixos config). When the plugin ecosystem fully migrates to
			-- main branch + nvim 0.12, swap this for a vim.treesitter.start-based config.
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "javascript", "typescript", "lua", "markdown", "markdown_inline" },
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

			-- Built-in tree inspector (replaces the deprecated playground plugin)
			vim.keymap.set("n", "<leader>T", ":InspectTree<CR>", { desc = "Inspect TreeSitter tree" })
		end,
	},
}
