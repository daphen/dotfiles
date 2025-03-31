return {
	"nvzone/minty",
	dependencies = {
		"nvzone/volt",
	},
	event = { "VeryLazy" },
	config = function()
		require("minty").setup()

		vim.keymap.set("n", "<leader>Ch", "<cmd>Huefy<CR>", { desc = "Huefy" })
		vim.keymap.set("n", "<leader>Cs", "<cmd>Shades<CR>", { desc = "Shades" })
	end,
}
