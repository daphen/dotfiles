return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-tree/nvim-web-devicons",
			"folke/todo-comments.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local transform_mod = require("telescope.actions.mt").transform_mod

			local trouble = require("trouble")

			-- or create your custom action
			local custom_actions = transform_mod({
				open_trouble_qflist = function()
					trouble.toggle("quickfix")
				end,
			})

			telescope.setup({
				defaults = {
					path_display = { "smart" },
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous, -- move to prev result
							["<C-j>"] = actions.move_selection_next, -- move to next result
							["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
						},
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			})

			telescope.load_extension("fzf")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find file" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Find grep" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Search diagnostics" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find existing buffers" })
			vim.keymap.set("n", "<leader>fa", builtin.oldfiles, { desc = 'Find Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Goto References" })
			vim.keymap.set("n", "<leader>fo", builtin.help_tags, { desc = "Search help" })
			vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "Search jumplist" })
			vim.keymap.set("n", "<leader>fq", builtin.quickfix, { desc = "Search quickfix list" })
			vim.keymap.set("n", "<leader>fM", builtin.marks, { desc = "Search marks" })

			vim.keymap.set("n", "<leader>fw", function()
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "Fuzzily search in current buffer]" })

			vim.keymap.set("n", "<leader>fo", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "Find in open files" })
		end,
	},
}
