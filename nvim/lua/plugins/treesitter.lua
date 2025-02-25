return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			local config = require("nvim-treesitter.configs")
			config.setup({
				ensure_installed = { "javascript", "lua" },
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]]"] = { query = "@function.outer", desc = "Next function" },
						},
						goto_previous_start = {
							["[["] = { query = "@function.outer", desc = "Previous function" },
						},
					},
				},
			})

			-- Simple function to find the next/previous block opening
			local function find_block_opening(forward)
				local bufnr = vim.api.nvim_get_current_buf()
				local cursor_pos = vim.api.nvim_win_get_cursor(0)
				local cursor_row = cursor_pos[1] -- 1-based row position

				-- Get all lines in the buffer
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local line_count = #lines

				-- Find the next/previous line with a block opening
				local target_row = nil

				if forward then
					-- Search forward from current position
					for i = cursor_row, line_count do
						if i ~= cursor_row then -- Skip current line
							local line = lines[i]
							if line and line:match("{%s*$") then
								target_row = i
								break
							end
						end
					end

					-- Wrap around to the beginning if needed
					if not target_row then
						for i = 1, cursor_row - 1 do
							local line = lines[i]
							if line and line:match("{%s*$") then
								target_row = i
								break
							end
						end
					end
				else
					-- Search backward from current position
					for i = cursor_row - 1, 1, -1 do
						local line = lines[i]
						if line and line:match("{%s*$") then
							target_row = i
							break
						end
					end

					-- Wrap around to the end if needed
					if not target_row then
						for i = line_count, cursor_row, -1 do
							local line = lines[i]
							if line and line:match("{%s*$") then
								target_row = i
								break
							end
						end
					end
				end

				-- Move cursor to the target row if found
				if target_row then
					local target_line = lines[target_row]
					local brace_col = target_line:find("{")
					if brace_col then
						vim.api.nvim_win_set_cursor(0, { target_row, brace_col - 1 })
					else
						vim.api.nvim_win_set_cursor(0, { target_row, 0 })
					end
				end
			end

			-- Set up simple keymaps for block navigation
			vim.keymap.set("n", "}}", function()
				find_block_opening(true)
			end, { desc = "Next block opening" })

			vim.keymap.set("n", "{{", function()
				find_block_opening(false)
			end, { desc = "Previous block opening" })

			-- Function to find blocks within a selection
			local function find_block_in_selection(text, skip_first_line)
				-- Look for lines with opening braces
				local blocks = {}
				local lines = vim.split(text, "\n")

				for i, line in ipairs(lines) do
					-- Skip the first line if requested (useful for nested blocks)
					if (not skip_first_line or i > 1) and line:match("{%s*$") then
						table.insert(blocks, { line = i, col = line:find("{") })
					end
				end

				-- Return the first block if found
				if #blocks > 0 then
					return blocks[1]
				end
				return nil
			end

			-- Create a function to detect visual mode and apply appropriate selection
			local function visual_block_selection(forward, inward)
				-- Store the current mode before exiting visual mode
				local mode_char = vim.api.nvim_get_mode().mode:sub(1, 1)

				-- Store current position to check if we're already in a selection
				local start_pos = vim.fn.getpos("v")
				local current_pos = vim.fn.getpos(".")

				-- Get the current visual selection text if we're in a selection
				local selection_text = ""
				local start_line = 0
				local end_line = 0

				if start_pos[2] ~= 0 and current_pos[2] ~= 0 then
					start_line = math.min(start_pos[2], current_pos[2])
					end_line = math.max(start_pos[2], current_pos[2])
					local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
					selection_text = table.concat(lines, "\n")
				end

				-- Exit visual mode
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

				-- If we're already in a selection
				if start_pos[2] ~= 0 and current_pos[2] ~= 0 then
					if inward then
						-- Try to find a nested block within the current selection
						local nested = find_block_in_selection(selection_text, true) -- Skip first line for nested blocks

						if nested then
							-- Calculate the absolute position of the nested block
							local abs_line = start_line - 1 + nested.line
							vim.api.nvim_win_set_cursor(0, { abs_line, nested.col - 1 })
						else
							-- If no nested block found, just stay at current position
							vim.api.nvim_win_set_cursor(0, { current_pos[2], current_pos[3] })

							-- If we're in }} mode and no nested block found, try next block
							if forward then
								find_block_opening(true)
							end
						end
					else
						-- For outward navigation, get the buffer content before the selection
						local before_selection = ""
						if start_line > 1 then
							local before_lines = vim.api.nvim_buf_get_lines(0, 0, start_line - 1, false)
							before_selection = table.concat(before_lines, "\n")
						end

						-- Find the closest block before our selection
						local parent = nil
						if before_selection ~= "" then
							-- Search backwards through the text
							local reversed_lines = vim.split(before_selection, "\n")
							for i = #reversed_lines, 1, -1 do
								local line = reversed_lines[i]
								if line:match("{%s*$") then
									parent = { line = i, col = line:find("{") }
									break
								end
							end
						end

						if parent then
							-- Go to the parent block
							vim.api.nvim_win_set_cursor(0, { parent.line, parent.col - 1 })
						else
							-- If no parent found, revert to original behavior
							find_block_opening(forward)
						end
					end
				else
					-- Standard behavior for first selection
					find_block_opening(forward)
				end

				-- Apply the appropriate selection based on the original mode
				if mode_char == "V" then
					-- Line-wise visual mode - select lines with V%
					vim.api.nvim_feedkeys("V%", "n", false)
				else
					-- Character-wise visual mode - select characters
					vim.api.nvim_feedkeys("vi{", "n", false)
				end
			end

			-- Visual mode mappings for block selection
			vim.keymap.set("x", "{{", function()
				visual_block_selection(false, false)
			end, { desc = "Select parent block" })

			vim.keymap.set("x", "}}", function()
				visual_block_selection(true, true)
			end, { desc = "Select nested block or next block" })
		end,
	},
}
