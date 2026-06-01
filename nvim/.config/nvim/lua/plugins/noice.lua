return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		require("notify").setup({
			stages = "static",
			background_colour = "#000000",
		})

		require("noice").setup({
			presets = {
				command_palette = true,
				long_message_to_split = true,
			},
			lsp = { override = {} },
			-- Both streams go through Noice so :Noice history is unified.
			messages = {
				enabled = true,
				view = "mini",
				view_error = "notify",
				view_warn = "notify",
				view_history = "split", -- :Noice history opens a real split
				view_search = "virtualtext",
			},
			notify = { enabled = true },
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
		vim.keymap.set("n", "<leader>nh", function() require("noice").cmd("history") end, { desc = "All messages (Noice history)" })
		vim.keymap.set("n", "<leader>nd", function() require("noice").cmd("dismiss") end, { desc = "Dismiss visible notifications" })

		-- :messages → Noice history. Guarded so it only expands when typed alone.
		vim.cmd([[
			cnoreabbrev <expr> messages (getcmdtype() == ':' && getcmdline() ==# 'messages') ? 'Noice history' : 'messages'
		]])
	end,
}
