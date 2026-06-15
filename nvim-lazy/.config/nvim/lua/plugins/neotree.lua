return {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>o", "<cmd>Neotree toggle position=float<cr>", desc = "Toggle NeoTree" },
	},
	config = function()
		require("neo-tree").setup({
			popup_border_style = "rounded",
			default_component_configs = {
				filesystem = {
					follow_current_file = {
						enabled = true,
						leave_dirs_open = true,
					},
					filtered_items = {
						visible = true,
						hide_dotfiles = false,
						hide_gitignored = true,
						never_show = {
							".DS_Store",
							"thumbs.db",
						},
					},
				},
				buffers = {
					follow_current_file = {
						enabled = true,
						leave_dirs_open = false,
					},
				},
			},
		})
	end,
}
