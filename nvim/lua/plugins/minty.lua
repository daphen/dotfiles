return {
	"nvchad/minty",
	dependencies = {
		"nvchad/volt",
	},
	config = function()
		vim.keymap.set("n", "<leader>C", function()
			require("minty.huefy").open({ border = true })
		end)
	end,
}
