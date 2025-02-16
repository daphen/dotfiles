return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")
		local utils = require("utils")

		local root_markers = { ".git", "package.json", "pnpm-workspace.yaml" }
		local prettier_configs = {
			".prettierrc",
			".prettierrc.json",
			".prettierrc.js",
			"prettier.config.js",
			"prettier.config.mjs",
		}

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				less = { "prettier" },
				scss = { "prettier" },
				markdown = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				lua = { "stylua" },
				python = { "black" },
			},
			formatters = {
				black = {
					cwd = require("conform.util").root_file({ "pyproject.toml" }),
				},
				prettier = {
					command = function()
						local current_path = utils.current_path()
						local root_path = utils.find_root_with_markers(current_path, root_markers)
						if not root_path then
							return vim.fn.executable("prettier") == 1 and "prettier" or nil
						end

						local sep = package.config:sub(1, 1)
						local paths = {
							root_path .. sep .. "node_modules" .. sep .. ".bin" .. sep .. "prettier",
							vim.fn.glob(
								root_path
									.. sep
									.. ".pnpm"
									.. sep
									.. "prettier@*"
									.. sep
									.. "node_modules"
									.. sep
									.. "prettier"
									.. sep
									.. "bin"
									.. sep
									.. "prettier.cjs"
							),
						}

						for _, path in ipairs(paths) do
							if vim.fn.executable(path) == 1 then
								return path
							end
						end

						return vim.fn.executable("prettier") == 1 and "prettier" or nil
					end,
					args = function(_, ctx)
						local current_path = utils.current_path()
						local root_path = utils.find_root_with_markers(current_path, root_markers)
						local args = { "--stdin-filepath", ctx.filename }

						if root_path then
							local sep = package.config:sub(1, 1)
							for _, config in ipairs(prettier_configs) do
								local config_path = root_path .. sep .. config
								if vim.fn.filereadable(config_path) ~= 0 then
									-- Use vim.list_extend to combine the tables
									vim.list_extend(args, { "--config", config_path })
									break
								end
							end
						end

						return args
					end,
					cwd = function()
						local current_path = utils.current_path()
						return utils.find_root_with_markers(current_path, root_markers) or vim.fn.getcwd()
					end,
				},
			},
			format_after_save = {
				timeout_ms = 2000,
				lsp_fallback = true,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout = 500,
			})
		end, { desc = "Format file or range" })
	end,
}
