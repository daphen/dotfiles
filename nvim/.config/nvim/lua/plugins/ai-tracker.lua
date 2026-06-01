return {
	name = "ai-tracker",
	dir = vim.fn.stdpath("config") .. "/lua/ai-tracker",

	lazy = false,
	priority = 90,

	config = function()
		require("ai-tracker").setup()
	end,

	keys = {
		{ "<C-g><C-g>", function() require("ai-tracker").show() end, desc = "AI Tracker: changed files inbox" },
		{ "<C-g>t", function() require("ai-tracker").toggle_follow() end, desc = "AI Tracker: toggle follow mode" },
	},

	cmd = { "AITrackerInbox", "AITrackerStatus", "AITrackerFollow", "AITrackerRefresh", "AITrackerDiagnose", "AITrackerDebug", "AITrackerClearCache" },
}
