return {
	name = "file-watcher",
	dir = vim.fn.stdpath("config") .. "/lua/file-watcher",
	event = "VeryLazy",
	config = function()
		require("file-watcher").setup()
	end,
}
