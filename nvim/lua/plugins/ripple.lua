return {
	"ian-howell/ripple.nvim",
	config = function()
		require("ripple").setup({
			vertical_step_size = 1,
			horizontal_step_size = 1,
			keys = {
				expand_right = { "<C-M-L>", mode = { "n", "v" }, desc = "expand right" },
				expand_left = { "<C-M-H>", mode = { "n", "v" }, desc = "expand left" },
				expand_up = { "<C-M-K>", mode = { "n", "v" }, desc = "expand up" },
				expand_down = { "<C-M-J>", mode = { "n", "v" }, desc = "expand down" },
			},
		})
	end,
}
