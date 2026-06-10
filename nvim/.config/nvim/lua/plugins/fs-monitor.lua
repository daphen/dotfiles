return {
	"bassamsdata/fs-monitor.nvim",
	event = "VeryLazy",
	opts = {
		monitor = {
			debounce_ms = 300,
			respect_gitignore = true,
			max_depth = 6,
			max_file_size = 1024 * 1024 * 2,
		},
	},
	keys = {
		{ "<leader>fm", function() require("fs-monitor").show_changes() end, desc = "fs-monitor: show changes" },
		{ "<leader>fM", function() require("fs-monitor").create_checkpoint(nil, vim.fn.input("checkpoint label: ")) end, desc = "fs-monitor: checkpoint" },
	},
}
