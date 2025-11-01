return {
	"suliatis/jumppack",
	config = function()
		require("Jumppack").setup({
			window = {
				config = function()
					local height = math.floor(vim.o.lines * 0.9)
					local width = math.floor(vim.o.columns * 0.9)
					return {
						relative = "editor",
						row = math.floor((vim.o.lines - height) / 2),
						col = math.floor((vim.o.columns - width) / 2),
						width = width,
						height = height,
						border = "rounded",
						title = " Jumplist ",
						title_pos = "center",
					}
				end,
			},
		})
	end,
}
