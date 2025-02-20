return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		indent = { enabled = false },
		input = { enabled = true },
		notifier = {
			enabled = true,
		},
		quickfile = { enabled = true },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		picker = { enabled = true },
		words = { enabled = false },
		terminal = {
			win = {
				style = {
					position = "float",
					backdrop = 60,
					height = 0.9,
					width = 0.9,
					zindex = 50,
					border = "rounded",
				},
			},
		},
	},
	keys = {
		{
			mode = { "n", "t" },
			"<c-t>",
			function()
				Snacks.terminal(nil)
			end,
			desc = "Toggle Terminal",
		},
		term_normal = {
			"<esc>",
			function(self)
				if not self.esc_timer then
					self.esc_timer = vim.defer_fn(function()
						self.esc_timer = nil
					end, 200)
					return "<esc>"
				end
				self.esc_timer = nil
				return "<C-\\><C-n>"
			end,
			mode = "t",
			expr = true,
			desc = "Double escape to normal mode",
		},
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>Z",
			function()
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<leader>nh",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>bd",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>gb",
			function()
				Snacks.git.blame_line()
			end,
			desc = "Git Blame Line",
		},
		{
			"<leader>gf",
			function()
				Snacks.lazygit.log_file()
			end,
			desc = "Lazygit Current File History",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>gl",
			function()
				Snacks.lazygit.log()
			end,
			desc = "Lazygit Log (cwd)",
		},
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.grep()
			end,
			desc = "Find Grep",
		},
		{
			"<leader>fh",
			function()
				Snacks.picker.help()
			end,
			desc = "Search Help",
		},
		{
			"<leader>fd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Search Diagnostics",
		},
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Find Buffers",
		},
		{
			"<leader>fa",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent Files",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.lsp_references()
			end,
			desc = "LSP References",
		},
		{
			"<leader>fj",
			function()
				Snacks.picker.jumps()
			end,
			desc = "Search Jumplist",
		},
		{
			"<leader>fq",
			function()
				Snacks.picker.qflist()
			end,
			desc = "Search Quickfix",
		},
		{
			"<leader>fM",
			function()
				Snacks.picker.marks()
			end,
			desc = "Search Marks",
		},
		{
			"<C-f>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart find files",
		},
		{
			"<leader>fw",
			function()
				Snacks.picker.lines()
			end,
			desc = "Search Current Buffer",
		},
		{
			"<leader>fo",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Search Open Files",
		},
		-- Additional useful picker mappings you might want
		{
			"<leader>fs",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		{
			"<leader>gc",
			function()
				Snacks.picker.git_commits()
			end,
			desc = "Git Commits",
		},
	},
}
