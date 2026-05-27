return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{ "<C-g>j", function() require("gitsigns").next_hunk() end, desc = "Next hunk" },
			{ "<C-g>k", function() require("gitsigns").prev_hunk() end, desc = "Prev hunk" },
			{ "<C-g>d", function() require("gitsigns").preview_hunk_inline() end, desc = "Preview hunk (inline)" },
			{ "<C-g>o", function() require("gitsigns").toggle_linehl() end, desc = "Toggle linehl" },
		},
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "▁" },
					topdelete = { text = "▔" },
					changedelete = { text = "▎" },
				},
				linehl = false,
				-- show_deleted was deprecated upstream; for inline view of
				-- removed lines, use preview_hunk_inline() instead (bound to
				-- <C-g>d in plugins/ai-tracker.lua).
				on_attach = function(bufnr)
					local gs = require("gitsigns")

					-- Align gitsigns' base with hunk-nvim/signs.lua. Without this,
					-- gitsigns compares against HEAD and shows no hunks when the
					-- branch's changes are already committed (working tree == HEAD).
					-- signs.lua diffs against merge-base-with-trunk so signs light
					-- up — gitsigns needs the same base for ]h/[h, stage, preview
					-- to be useful in this scenario. Deferred via vim.schedule so
					-- it runs after both plugins have finished initializing on
					-- first-buffer load.
					vim.schedule(function()
						local ok, signs = pcall(require, "hunk-nvim.signs")
						if not (ok and signs.resolve_base) then return end
						local base = signs.resolve_base()
						if base and base ~= "" and base ~= "HEAD" then
							pcall(gs.change_base, base, true)
						end
					end)

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					map("n", "]h", function()
						if vim.wo.diff then
							return "]h"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Next hunk" })

					map("n", "[h", function()
						if vim.wo.diff then
							return "[h"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Previous hunk" })

					map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
					map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
					map("v", "<leader>hs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Stage hunk" })
					map("v", "<leader>hr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Reset hunk" })
					map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
					map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
					map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
					map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
					map("n", "<leader>hb", function()
						gs.blame_line({ full = true })
					end, { desc = "Blame line" })
					map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
					map("n", "<leader>hD", function()
						gs.diffthis("~")
					end, { desc = "Diff this ~" })

					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
				end,
			})
		end,
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "DiffView Open" },
			{ "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "DiffView Close" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch History" },
		},
		opts = {
			enhanced_diff_hl = true,
			view = {
				default = {
					layout = "diff2_horizontal",
				},
				file_history = {
					layout = "diff2_horizontal",
				},
			},
		},
	},
}
