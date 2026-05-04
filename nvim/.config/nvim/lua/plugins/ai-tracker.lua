return {
	-- AI Changes Tracker
	-- Tracks file changes made by AI coding assistants (OpenCode, Claude Code, etc.)
	name = "ai-tracker",
	dir = vim.fn.stdpath("config") .. "/lua/ai-tracker",
	dependencies = {
		"folke/snacks.nvim", -- Required for picker functionality
	},

	-- Skip in kitty-scrollback nvim instances — those are pagers, not editors,
	-- and shouldn't react to AI edits at all.
	cond = function()
		return vim.env.KITTY_SCROLLBACK_NVIM ~= "true"
	end,

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

		-- Hunk navigation / diff preview (delegated to gitsigns since we use git diffs now)
		{
			"<C-g>j",
			function() require("gitsigns").next_hunk() end,
			desc = "Next hunk",
		},
		{
			"<C-g>k",
			function() require("gitsigns").prev_hunk() end,
			desc = "Previous hunk",
		},
		{
			"<C-g>d",
			function() require("gitsigns").preview_hunk_inline() end,
			desc = "Preview hunk (inline)",
		},
		{
			"<C-g>u",
			function() require("ai-tracker").jump_to_unread() end,
			desc = "Jump to first unread AI edit",
		},
		{
			"<C-f>",
			function() require("ai-tracker").jump_to_latest() end,
			desc = "Jump to latest AI edit",
		},
		{
			"<C-g>r",
			function() require("ai-tracker").reset_tracking() end,
			desc = "Reset AI tracking (manual clear)",
		},
		{
			"<C-g>t",
			function() require("ai-tracker.preview").toggle() end,
			desc = "Toggle AI Tracker preview gate",
		},
		{
			"<C-g><leader>",
			function() require("ai-tracker.preview").toggle_pause() end,
			desc = "Pause/resume Claude tool calls",
		},
		{
			"<C-g>y",
			function() require("ai-tracker.preview").ask_about_chunk() end,
			desc = "Send chunk + question to Claude",
		},
		{
			"<C-g>o",
			function() require("gitsigns").toggle_linehl() end,
			desc = "Toggle git diff overlay (linehl)",
		},
		{
			"]g",
			function() require("ai-tracker.preview").next_chunk() end,
			desc = "Next AI chunk / git hunk",
		},
		{
			"[g",
			function() require("ai-tracker.preview").prev_chunk() end,
			desc = "Prev AI chunk / git hunk",
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
		"AITrackerUnread",
		"AITrackerJumpLatest",
		"AITrackerPreviewInstall",
		"AITrackerPreviewToggle",
		"AITrackerPause",
		"AITrackerAsk",
		"AITrackerChannelInstall",
	},
}
