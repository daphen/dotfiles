return {
	"j-morano/buffer_manager.nvim",
	config = function()
		require("buffer_manager").setup({
			order_buffers = "lastused",
		})

		vim.keymap.set("n", "<C-f>", function()
			require("buffer_manager.ui").toggle_quick_menu()
		end)
	end,
}
