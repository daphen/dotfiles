return {
	"noice.nvim",
	event = "VimEnter",
	after = function()
		require("notify").setup({
			stages = "static",
			background_colour = "#000000",
		})

		require("noice").setup({
			presets = {
				command_palette = true,
				long_message_to_split = true,
			},
			lsp = {
				-- Disable all LSP overrides to use native Neovim borders
				override = {},
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

		vim.keymap.set("n", "<leader>ne", function() require("noice").cmd("errors") end)
	end,
}
