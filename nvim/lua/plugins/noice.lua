return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		require("notify").setup({
			stages = "fade",
			timeout = 500,
			background_colour = "#000000",
		})

		require("noice").setup({
			presets = {
				lsp_doc_border = true,
				command_palette = true,
				long_message_to_split = true,
			},
			routes = {
				{
					filter = {
						event = "notify",
						find = "No information available",
					},
					opts = { skip = true },
				},
				{
					filter = {
						event = "msg_show",
						kind = "",
						find = "written",
					},
					opts = { skip = true },
				},
			},
		})

		vim.keymap.set("n", "<leader>ne", function()
			require("noice").cmd("errors")
		end)
	end,
}
