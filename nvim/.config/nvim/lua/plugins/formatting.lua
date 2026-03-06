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

		-- Check if we're in the Lovable project
		local function is_lovable_project(path)
			local root = utils.find_root_with_markers(path, { ".treefmt.toml", ".oxfmtrc.json" })
			return root ~= nil
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
				-- Use lovable_format for these filetypes if in Lovable project, otherwise prettier
				javascript = { "lovable_format", "prettier" },
				typescript = { "lovable_format", "prettier" },
				javascriptreact = { "lovable_format", "prettier" },
				typescriptreact = { "lovable_format", "prettier" },
				css = { "lovable_format", "prettier" },
				html = { "lovable_format", "prettier" },
				less = { "lovable_format", "prettier" },
				scss = { "lovable_format", "prettier" },
				markdown = { "lovable_format", "prettier" },
				json = { "lovable_format", "prettier" },
				yaml = { "lovable_format", "prettier" },
				-- Prettier-only for these
				svelte = { "prettier" },
				vue = { "prettier" },
				svg = { "prettier" },
				-- Other formatters
				lua = { "stylua" },
				python = { "black" },
			},
			formatters = {
				-- Lovable project formatter (uses treefmt + oxfmt)
				lovable_format = {
					condition = function()
						local current_path = utils.current_path()
						return is_lovable_project(current_path)
					end,
					command = function()
						local current_path = utils.current_path()
						local root = utils.find_root_with_markers(current_path, { ".treefmt.toml" })
						if root then
							local sep = package.config:sub(1, 1)
							local format_bin = root .. sep .. "bin" .. sep .. "format"
							if vim.fn.executable(format_bin) == 1 then
								return format_bin
							end
						end
						return "format" -- Fallback to PATH
					end,
					args = { "$FILENAME" },
					stdin = false,
					cwd = function()
						local current_path = utils.current_path()
						return utils.find_root_with_markers(current_path, { ".treefmt.toml" }) or vim.fn.getcwd()
					end,
				},
				black = {
					cwd = require("conform.util").root_file({ "pyproject.toml" }),
				},
				prettier = {
					condition = function()
						local current_path = utils.current_path()
						
						-- Don't use prettier in Lovable project (lovable_format handles it)
						if is_lovable_project(current_path) then
							return false
						end
						
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
