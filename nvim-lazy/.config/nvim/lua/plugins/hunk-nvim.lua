return {
	-- hunk-nvim — git-driven inline diff overlay (signs.lua). Self-gates
	-- on being in a git repo with a reachable base, so safe everywhere.
	name = "hunk-nvim",
	dir = vim.fn.stdpath("config") .. "/lua/hunk-nvim",

	lazy = false,
	priority = 100,

	config = function()
		require("hunk-nvim").setup()
	end,
}
