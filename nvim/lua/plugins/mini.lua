return {
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.comment").setup()
			require("mini.surround").setup()
			local mini_files = require("mini.files")

			local function setup_mini_files()
				-- Calculate dimensions
				local PADDING = 2
				local win_width = math.floor((vim.o.columns - (PADDING * 4)) / 4)

				mini_files.setup({
					options = {
						show_hidden = true,
					},
					windows = {
						preview = true,
						max_number = 4,
						width_focus = win_width,
						width_nofocus = win_width,
						width_preview = win_width,
					},
					mappings = {
						go_in_plus = "<CR>",
						synchronize = ":",
						close = "q",
					},
				})
			end

			local function is_preview_window(win_id)
				local buf_id = vim.api.nvim_win_get_buf(win_id)
				local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf_id, 0, -1, false)
				if not ok or #lines == 0 then return false end
				return not vim.startswith(lines[1], "/")
			end

			-- initial window styling
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesWindowOpen",
				callback = function(args)
					local win_id = args.data.win_id
					local config = vim.api.nvim_win_get_config(win_id)
					config.border = "rounded"
					config.height = math.floor(vim.o.lines * 0.48)
					config.title_pos = "right"
					vim.wo[win_id].relativenumber = true
					vim.wo[win_id].number = true
					vim.api.nvim_set_hl(0, "MiniFilesTitleFocused", { fg = "#ff7f33" })
					pcall(vim.api.nvim_win_set_config, win_id, config)
				end,
			})

			-- Height must be set in update because mini sets height explicitly after open
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesWindowUpdate",
				callback = function(args)
					local win_id = args.data.win_id
					local config = vim.api.nvim_win_get_config(win_id)
					local total_height = vim.o.lines
					local total_width = vim.o.columns

					if not vim.api.nvim_win_is_valid(win_id) then return end

					if is_preview_window(win_id) then
						config.width = total_width
						config.height = math.floor(total_height * 0.44)
						config.row = total_height
						config.col = 0
					else
						-- Regular explorer window
						config.height = math.floor(total_height * 0.48)
					end

					pcall(vim.api.nvim_win_set_config, win_id, config)
				end,
			})

			vim.keymap.set("n", "<leader>e", function()
				setup_mini_files()
				mini_files.open(vim.api.nvim_buf_get_name(0))

				-- Navigate to parent directories and back to create a two level context view
				for _ = 1, 2 do
					mini_files.go_out()
				end

				for _ = 1, 2 do
					mini_files.go_in()
				end
			end, { desc = "Open file explorer" })

			vim.keymap.set("n", "<leader>E", function()
				setup_mini_files()
				mini_files.open()
			end, { desc = "Open file explorer (cwd)" })
		end,
	},
}
