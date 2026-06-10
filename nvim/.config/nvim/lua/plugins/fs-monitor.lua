return {
	"bassamsdata/fs-monitor.nvim",
	event = "VeryLazy",
	config = function()
		local fm = require("fs-monitor")
		fm.setup({
			monitor = {
				debounce_ms = 300,
				respect_gitignore = true,
				max_depth = 6,
				max_file_size = 1024 * 1024 * 2,
			},
		})
		-- One default session per nvim instance watching cwd.
		vim.g._fs_monitor_session = fm.create_session()
		fm.start(vim.g._fs_monitor_session, vim.fn.getcwd())
	end,
	keys = {
		{
			"<leader>fm",
			function()
				require("fs-monitor").show_diff(vim.g._fs_monitor_session)
			end,
			desc = "fs-monitor: show diff",
		},
		{
			"<leader>fM",
			function()
				local label = vim.fn.input("checkpoint label: ")
				require("fs-monitor").create_checkpoint(vim.g._fs_monitor_session, label)
			end,
			desc = "fs-monitor: checkpoint",
		},
	},
}
