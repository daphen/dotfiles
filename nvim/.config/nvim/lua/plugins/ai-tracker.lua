return {
	-- AI Changes Tracker
	-- Tracks file changes made by AI coding assistants (OpenCode, Claude Code, etc.)
	name = "ai-tracker",
	dir = vim.fn.stdpath("config") .. "/lua/ai-tracker",
	dependencies = {
		"folke/snacks.nvim", -- Required for picker functionality
	},

	-- Load immediately at startup to show line highlights
	lazy = false,
	priority = 100, -- Load early but after theme

	config = function()
		require("ai-tracker").setup({
			-- Configuration options
			log_file = vim.fn.expand("~/.local/share/nvim/ai-changes.jsonl"),
			max_entries = 1000,
			auto_reload = true,
		})
	end,

	-- Key mappings (plugin loads at startup now, so these are just bindings)
	keys = {
		-- Main interfaces
		{
			"<C-g><C-g>",
			function() require("ai-tracker").show() end,
			desc = "AI Changes (by file)",
		},
		{
			"<C-g>a",
			function() require("ai-tracker").show_all_lines() end,
			desc = "AI Changes (all lines)",
		},
		{
			"<C-g>p",
			function() require("ai-tracker").show_grouped() end,
			desc = "AI Changes (grouped by prompt)",
		},
		{
			"<C-g>P",
			function() require("ai-tracker").show_prompt_files() end,
			desc = "AI Prompts & Files",
		},

		-- Navigation through changes
		{
			"<C-g>j",
			function() require("ai-tracker").next() end,
			desc = "Next AI change",
		},
		{
			"<C-g>k",
			function() require("ai-tracker").prev() end,
			desc = "Previous AI change",
		},
		{
			"<C-g>r",
			function() require("ai-tracker").reset_tracking() end,
			desc = "Reset AI tracking (manual clear)",
		},

		-- Manual annotation
		{
			"<leader>ap",
			function() require("ai-tracker").annotate_prompt() end,
			desc = "Annotate AI prompt",
		},

		-- Cleanup
		{
			"<leader>ac",
			function() require("ai-tracker").clear_clean_files() end,
			desc = "Clear AI tracking for clean files",
		},
		{
			"<leader>aR",
			function() require("ai-tracker").reset_tracking() end,
			desc = "Reset AI tracking (new feature)",
		},
	},

	-- Register commands
	cmd = {
		"AITracker",
		"AITrackerFile",
		"AITrackerGrouped",
		"AITrackerSessions",
		"AITrackerPromptFiles",
		"AIPrompt",
		"AITrackerClear",
		"AITrackerReload",
	},
}
