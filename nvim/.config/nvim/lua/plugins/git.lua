return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			-- Hunk navigation goes to hunk-nvim/signs.lua so it works
			-- everywhere (proart + LoL sandboxes where gitsigns can't attach
			-- due to broken/shallow git history). Signs visible = nav works.
			{ "<C-g>j", function() require("hunk-nvim.signs").next_hunk() end, desc = "Next hunk" },
			{ "<C-g>k", function() require("hunk-nvim.signs").prev_hunk() end, desc = "Prev hunk" },
			-- Stay on gitsigns — these only matter on proart where gitsigns attaches.
			{ "<C-g>d", function() require("gitsigns").preview_hunk_inline() end, desc = "Preview hunk (inline)" },
			{ "<C-g>o", function() require("gitsigns").toggle_linehl() end, desc = "Toggle linehl" },
		},
		config = function()
			-- Compute diff base at config time so gitsigns starts with the
			-- merge-base-with-trunk instead of its default (':0' staged index).
			-- on_attach's change_base call had a race window we couldn't
			-- close reliably; passing `base` in setup avoids it.
			local base
			local ok, signs = pcall(require, "hunk-nvim.signs")
			if ok and signs.resolve_base then
				local resolved = signs.resolve_base()
				if resolved and resolved ~= "" and resolved ~= "HEAD" then
					base = resolved
				end
			end

			require("gitsigns").setup({
				signs = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "▁" },
					topdelete = { text = "▔" },
					changedelete = { text = "▎" },
				},
				base = base,
				linehl = false,
				on_attach = function(bufnr)
					local gs = require("gitsigns")

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
