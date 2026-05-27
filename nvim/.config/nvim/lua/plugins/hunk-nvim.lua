return {
	-- hunk-nvim — git-driven inline diff overlay (signs.lua) on every host,
	-- plus optional cursor sync to a running `hunk diff --watch` TUI inside
	-- LoL sandboxes. The cursor-sync side gates itself internally on
	-- HUNK_NVIM_ENABLE; the signs overlay self-gates on being in a git
	-- repo with a reachable base commit, so it runs everywhere safely.
	name = "hunk-nvim",
	dir = vim.fn.stdpath("config") .. "/lua/hunk-nvim",

	lazy = false,
	priority = 100,

	config = function()
		require("hunk-nvim").setup()
	end,
}
