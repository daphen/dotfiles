return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")
		local utils = require("utils")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				svg = { "prettier" },
				html = { "prettier" },
				less = { "prettier" },
				scss = { "prettier" },
				markdown = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
			},
			format_after_save = {
				lsp_fallback = false,
				timeout = 500,
			},
			formatters = {
				prettier = {
					condition = function()
						local root_markers = { ".git" }
						local target_files = { ".prettierrc", ".prettierrc.json", "prettier.config.mjs" }
						return utils.root_has_file(utils.current_path(), root_markers, target_files)
					end,
				},
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>=", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout = 500,
			})
		end, { desc = "Format file or range" })
	end,
}
