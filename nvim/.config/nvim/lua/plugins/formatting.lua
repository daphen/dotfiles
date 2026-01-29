return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")
		local utils = require("utils")

		local function find_project_root(path)
			-- Try monorepo/project root markers first
			local root = utils.find_root_with_markers(path, { ".prettierrc", ".prettierrc.json", "pnpm-workspace.yaml", ".git" })
			if root then return root end
			-- Fallback to package.json for simple projects
			return utils.find_root_with_markers(path, { "package.json" })
		end
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
				svg = { "prettier" },
				lua = { "stylua" },
				python = { "black" },
			},
			formatters = {
				black = {
					cwd = require("conform.util").root_file({ "pyproject.toml" }),
				},
				prettier = {
					condition = function()
						local current_path = utils.current_path()
						local root_path = find_project_root(current_path)

						-- Check global prettier first
						if vim.fn.executable("prettier") == 1 then
							return true
						end

						if not root_path then
							return false
						end

						local sep = package.config:sub(1, 1)
						local paths = {
							root_path .. sep .. "node_modules" .. sep .. ".bin" .. sep .. "prettier",
						}

						-- Check for pnpm prettier
						local pnpm_prettier = vim.fn.glob(
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
						)
						if pnpm_prettier ~= "" then
							table.insert(paths, pnpm_prettier)
						end

						for _, path in ipairs(paths) do
							if path ~= "" and vim.fn.executable(path) == 1 then
								return true
							end
						end

						return false
					end,
					command = function()
						local current_path = utils.current_path()
						local root_path = find_project_root(current_path)
						if not root_path then
							return "prettier"
						end

						local sep = package.config:sub(1, 1)
						local paths = {
							root_path .. sep .. "node_modules" .. sep .. ".bin" .. sep .. "prettier",
						}

						-- Check for pnpm prettier
						local pnpm_prettier = vim.fn.glob(
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
						)
						if pnpm_prettier ~= "" then
							table.insert(paths, pnpm_prettier)
						end

						for _, path in ipairs(paths) do
							if path ~= "" and vim.fn.executable(path) == 1 then
								return path
							end
						end

						return "prettier"
					end,
					args = function(_, ctx)
						local current_path = utils.current_path()
						local root_path = find_project_root(current_path)
						local args = { "--stdin-filepath", ctx.filename }

						if vim.fn.fnamemodify(ctx.filename, ":e") == "svg" then
							table.insert(args, "--parser")
							table.insert(args, "html")
						end

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
						return find_project_root(current_path) or vim.fn.getcwd()
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
