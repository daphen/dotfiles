return {
	{
		"quicker.nvim",
		-- keys triggers load from a cold start (toggle opens the qf);
		-- ft handles styling once a qf buffer exists.
		keys = {
			{ "<C-q>", function() require("quicker").toggle() end, desc = "Toggle quickfix" },
		},
		ft = "qf",
		after = function()
			require("quicker").setup({
				opts = {
					buflisted = false,
					number = true,
					relativenumber = true,
					signcolumn = "auto",
					winfixheight = true,
					wrap = false,
				},
				use_default_opts = true,
				edit = { enabled = true, autosave = "unmodified" },
				constrain_cursor = true,
				highlight = { treesitter = true, lsp = true, load_buffers = false },
				follow = { enabled = false },
				type_icons = { E = "󰅚 ", W = "󰀪 ", I = " ", N = " ", H = " " },
				borders = {
					vert = "┃",
					strong_header = "━", strong_cross = "╋", strong_end = "┫",
					soft_header = "╌", soft_cross = "╂", soft_end = "┨",
				},
			})
		end,
	},
}
