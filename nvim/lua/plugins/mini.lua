return {
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.comment").setup()
			require("mini.colors").setup()
			require("mini.surround").setup()
			local mini_files = require("mini.files")

			-- Calculate dimensions
			local PADDING = 2 -- Minimal padding
			local win_height = math.floor(vim.o.lines * 0.46)
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
					close = "q",
				},
			})

			local function is_preview_buffer(buf_id)
				local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf_id, 0, -1, false)
				if not ok or #lines == 0 then
					return false
				end
				return not vim.startswith(lines[1], "/")
			end

			-- Set up buffer-specific keymaps
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesBufferCreate",
				callback = function(args)
					local buf_id = args.data.buf_id

					-- Only set up mappings for preview buffers
					if is_preview_buffer(buf_id) then
						-- Scroll preview window
						vim.keymap.set("n", "<C-d>", "<C-d>zz", { buffer = buf_id, desc = "Scroll down" })
						vim.keymap.set("n", "<C-u>", "<C-u>zz", { buffer = buf_id, desc = "Scroll up" })
						vim.keymap.set("n", "<C-f>", "<C-f>zz", { buffer = buf_id, desc = "Page down" })
						vim.keymap.set("n", "<C-b>", "<C-b>zz", { buffer = buf_id, desc = "Page up" })
						vim.keymap.set("n", "J", "5j", { buffer = buf_id, desc = "Jump 5 lines down" })
						vim.keymap.set("n", "K", "5k", { buffer = buf_id, desc = "Jump 5 lines up" })
						vim.keymap.set("n", "gg", "ggzz", { buffer = buf_id, desc = "Go to top" })
						vim.keymap.set("n", "G", "Gzz", { buffer = buf_id, desc = "Go to bottom" })
					end
				end,
			})

			-- Function to check if a window is a preview window
			local function is_preview_window(win_id)
				local buf_id = vim.api.nvim_win_get_buf(win_id)
				local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf_id, 0, -1, false)
				if not ok or #lines == 0 then
					return false
				end
				return not vim.startswith(lines[1], "/")
			end

			-- Set up initial window styling
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesWindowOpen",
				callback = function(args)
					local win_id = args.data.win_id
					local config = vim.api.nvim_win_get_config(win_id)
					config.border = "rounded"
					config.title_pos = "right"
					pcall(vim.api.nvim_win_set_config, win_id, config)
				end,
			})

			-- Handle window updates (height and preview positioning)
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesWindowUpdate",
				callback = function(args)
					local win_id = args.data.win_id

					-- Check if window is still valid
					if not vim.api.nvim_win_is_valid(win_id) then
						return
					end

					-- Check if this is a preview window
					if is_preview_window(win_id) then
						local config = vim.api.nvim_win_get_config(win_id)

						config.width = math.floor(vim.o.columns)

						config.height = math.floor(vim.o.lines * 0.48)

						-- Position immediately below top panes with minimal gap
						config.row = math.floor(vim.o.lines)

						-- Center horizontally (match explorer windows)
						config.col = 0

						pcall(vim.api.nvim_win_set_config, win_id, config)
					else
						-- Regular explorer window
						local config = vim.api.nvim_win_get_config(win_id)
						config.height = win_height
						pcall(vim.api.nvim_win_set_config, win_id, config)
					end
				end,
			})

			vim.keymap.set("n", "<leader>E", function()
				mini_files.open(vim.api.nvim_buf_get_name(0))
			end, { desc = "Open file explorer" })

			vim.keymap.set("n", "<leader>e", function()
				mini_files.open()
			end, { desc = "Open file explorer (cwd)" })
		end,
	},
}
