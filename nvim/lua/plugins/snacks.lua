return {
	"folke/snacks.nvim",
	priority = 1000,
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		indent = { enabled = false },
		input = { enabled = true },
		words = { enabled = false },
		notifier = {
			enabled = false,
		},
		quickfile = { enabled = true },
		picker = { enabled = true },
		scope = { enabled = true },
		-- terminal = {
		-- 	win = {
		-- 		style = {
		-- 			position = "float",
		-- 			backdrop = 60,
		-- 			height = 0.9,
		-- 			width = 0.9,
		-- 			zindex = 50,
		-- 			border = "rounded",
		-- 		},
		-- 	},
		-- },
	},
	keys = {
		-- {
		-- 	mode = { "n", "t" },
		-- 	"<c-t>",
		-- 	function() Snacks.terminal(nil) end,
		-- 	desc = "Toggle Terminal",
		-- },
		-- term_normal = {
		-- 	"<esc>",
		-- 	function(self)
		-- 		if not self.esc_timer then
		-- 			self.esc_timer = vim.defer_fn(function() self.esc_timer = nil end, 200)
		-- 			return "<esc>"
		-- 		end
		-- 		self.esc_timer = nil
		-- 		return "<C-\\><C-n>"
		-- 	end,
		-- 	mode = "t",
		-- 	expr = true,
		-- 	desc = "Double escape to normal mode",
		-- },
		{ "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
		{ "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
		{ "<leader>nh", function() Snacks.notifier.show_history() end, desc = "Notification History" },
		{ "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
		{ "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
		{ "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
		{ "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
		{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
		{ "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
		{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
		{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Find Grep" },
		{ "<leader>fh", function() Snacks.picker.help() end, desc = "Search Help" },
		{ "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Search Diagnostics" },
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find Buffers" },
		{ "<C-f>", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Find Recent" },
		{ "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
		{ "<leader>fr", function() Snacks.picker.lsp_references() end, desc = "LSP References" },
		{ "<leader>fj", function() Snacks.picker.jumps() end, desc = "Search Jumplist" },
		{ "<leader>fq", function() Snacks.picker.qflist() end, desc = "Search Quickfix" },
		{ "<leader>fm", function() Snacks.picker.marks() end, desc = "Search Marks" },
		{ "<leader>fw", function() Snacks.picker.lines() end, desc = "Search Current Buffer" },
		{ "<leader>fo", function() Snacks.picker.grep_buffers() end, desc = "Search Open Files" },
		-- Additional useful picker mappings you might want
		{ "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
		{ "<leader>gc", function() Snacks.picker.git_commits() end, desc = "Git Commits" },
		{ "<leader>u", function() Snacks.picker.undo() end, desc = "Undo History" },
		{ "<C-n>", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
		{ "<C-p>", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
	},
}
