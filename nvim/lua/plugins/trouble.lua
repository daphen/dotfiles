return {
	"folke/trouble.nvim",
	opts = {
		height = 20,
	},
	cmd = "Trouble",
	branch = "dev",
	keys = {
		{
			"<leader>xx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
	},
}
