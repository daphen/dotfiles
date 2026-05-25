return {
	-- hunk-nvim
	-- Mirrors the nvim cursor into a running `hunk diff --watch` TUI via
	-- hunk's session API. Active only when HUNK_NVIM_ENABLE is set (the
	-- daphen-env wrapper sets it inside LoL sandboxes); no-op locally on
	-- proart so editing without an agent doesn't drive an absent TUI.
	name = "hunk-nvim",
	dir = vim.fn.stdpath("config") .. "/lua/hunk-nvim",

	cond = function()
		local v = vim.env.HUNK_NVIM_ENABLE
		return v ~= nil and v ~= "" and v ~= "0"
	end,

	lazy = false,
	priority = 100,

	config = function()
		require("hunk-nvim").setup()
	end,
}
