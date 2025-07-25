return {
	"nvzone/floaterm",
	dependencies = "nvzone/volt",
	lazy = false,
	opts = {
		border = false,
		size = { h = 90, w = 90 },
		-- Default sets of terminals you'd like to open
		terminals = {
			{ name = "Terminal" },
			-- cmd can be function too
			{ name = "Scratch" },
		},
	},
	keys = {
		{
			"<C-t>",
			"<cmd>FloatermToggle<cr>",
			desc = "Toggle Floaterm",
			mode = { "n", "t" },
		},
		{
			"<esc><esc>",
			"<C-\\><C-n>",
			mode = "t",
			desc = "Double escape to enter scrollback mode in terminal",
		},
	},
}
