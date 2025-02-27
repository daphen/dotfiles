return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/playground",
		},
		config = function()
			-- First set up the basic TreeSitter configuration without the keymaps
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "javascript", "typescript", "lua" },
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				playground = {
					enable = true,
				},
				textobjects = {
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]]"] = "@function.outer",
						},
						goto_previous_start = {
							["[["] = "@function.outer",
						},
					},
				},
			})

			-- Add keymapping for TreeSitter playground
			vim.keymap.set("n", "<leader>tp", ":TSPlaygroundToggle<CR>", { desc = "Toggle TreeSitter playground" })

			-- Debug function to show messages
			local function debug_print(msg)
				vim.cmd('echom "DEBUG: ' .. msg .. '"')
			end

			-- Define our custom normal mode keymaps for block navigation
			vim.keymap.set("n", "}}", function()
				require("nvim-treesitter.textobjects.move").goto_next_start("@block.inner")
			end, { desc = "Go to next block" })

			vim.keymap.set("n", "{{", function()
				require("nvim-treesitter.textobjects.move").goto_previous_start("@block.inner")
			end, { desc = "Go to previous block" })

			-- Visual mode mappings for navigating and selecting blocks
			vim.keymap.set("x", "}}", function()
				debug_print("Visual mode }} triggered")
				local mode = vim.api.nvim_get_mode().mode
				debug_print("Mode: " .. mode)

				-- Store the current mode for later use
				local is_linewise = (mode:sub(1, 1) == "V")
				debug_print("Is linewise: " .. tostring(is_linewise))

				-- Exit visual mode
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true)

				-- Navigate to next block
				debug_print("Navigating to next block")
				require("nvim-treesitter.textobjects.move").goto_next_start("@block.inner")

				-- Wait a bit to ensure navigation completes
				vim.defer_fn(function()
					-- Select the block based on the original mode
					if is_linewise then
						debug_print("Selecting outer block (linewise)")
						vim.cmd("normal! %V%")
					else
						debug_print("Selecting inner block")
						vim.cmd("normal! vi{")
					end
				end, 10)
			end, { desc = "Select next block" })

			vim.keymap.set("x", "{{", function()
				debug_print("Visual mode {{ triggered")
				local mode = vim.api.nvim_get_mode().mode
				debug_print("Mode: " .. mode)

				-- Store the current mode for later use
				local is_linewise = (mode:sub(1, 1) == "V")
				debug_print("Is linewise: " .. tostring(is_linewise))

				-- Exit visual mode
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true)

				-- Navigate to previous block
				debug_print("Navigating to previous block")
				require("nvim-treesitter.textobjects.move").goto_previous_start("@block.inner")

				-- Wait a bit to ensure navigation completes
				vim.defer_fn(function()
					-- Select the block based on the original mode
					if is_linewise then
						debug_print("Selecting outer block (linewise)")
						vim.cmd("normal! %V%")
					else
						debug_print("Selecting inner block")
						vim.cmd("normal! vi{")
					end
				end, 10)
			end, { desc = "Select previous block" })
		end,
	},
}
