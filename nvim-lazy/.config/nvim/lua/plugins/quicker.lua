return {
	"stevearc/quicker.nvim",
	event = "FileType qf",
	opts = {},
	config = function()
		require("quicker").setup({
			-- Local options to set for quickfix
			opts = {
				buflisted = false,
				number = true,
				relativenumber = true,
				signcolumn = "auto",
				winfixheight = true,
				wrap = false,
			},
			-- Set to false to disable the default options in `opts`
			use_default_opts = true,
			-- Callback function to run any custom logic or keymaps for the quickfix buffer
			-- on_qf = function(bufnr) end,
			edit = {
				enabled = true,
				autosave = "unmodified",
			},
			constrain_cursor = true,
			highlight = {
				treesitter = true,
				lsp = true,
				load_buffers = false,
			},
			follow = {
				-- When quickfix window is open, scroll to closest item to the cursor
				enabled = false,
			},
			-- Map of quickfix item type to icon
			type_icons = {
				E = "󰅚 ",
				W = "󰀪 ",
				I = " ",
				N = " ",
				H = " ",
			},
			-- Border characters
			borders = {
				vert = "┃",
				-- Strong headers separate results from different files
				strong_header = "━",
				strong_cross = "╋",
				strong_end = "┫",
				-- Soft headers separate results within the same file
				soft_header = "╌",
				soft_cross = "╂",
				soft_end = "┨",
			},
		})

		vim.keymap.set("n", "<C-q>", function() require("quicker").toggle() end, { desc = "Toggle quickfix" })
	end,
}
