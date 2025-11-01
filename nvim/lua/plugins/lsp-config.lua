return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonUpdate", "MasonInstall", "MasonUninstall" },
		event = "VeryLazy", -- Load after startup to avoid session restoration conflicts
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			-- Disable automatic registry update on startup
			registries = {
				"github:mason-org/mason-registry",
			},
			max_concurrent_installers = 4,
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		event = "VeryLazy",
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = cmp_nvim_lsp.default_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = {
					"ts_ls",
					"eslint",
					"html",
					"cssls",
					"tailwindcss",
					"lua_ls",
					"emmet_ls",
					"svelte",
					"graphql",
					"pylsp",
				},
				automatic_installation = true,
				handlers = {
					-- Default handler for servers without custom config
					function(server_name)
						lspconfig[server_name].setup({
							capabilities = capabilities,
						})
					end,
					-- Custom handlers for servers with specific configs
					["html"] = function()
						lspconfig.html.setup({
							capabilities = capabilities,
							filetypes = { "hbs" },
						})
					end,
					["ts_ls"] = function()
						lspconfig.ts_ls.setup({
							capabilities = capabilities,
							handlers = {
								["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
									-- Process diagnostics
									for _, diagnostic in ipairs(result.diagnostics) do
										-- Filter ESLint diagnostics from ts_ls to prevent duplicates
										if diagnostic.source == "eslint" then
											diagnostic = nil
										-- Ensure TypeScript warnings show as warnings, not hints
										elseif diagnostic.code == 6133 then
											-- "declared but never read" should be a warning
											diagnostic.severity = vim.lsp.protocol.DiagnosticSeverity.Warning
										end
									end

									-- Filter out nil diagnostics
									result.diagnostics = vim.tbl_filter(function(d) return d ~= nil end, result.diagnostics)

									vim.lsp.handlers["textDocument/publishDiagnostics"](_, result, ctx, config)
								end,
							},
						})
					end,
					["eslint"] = function()
						lspconfig.eslint.setup({
							capabilities = capabilities,
							on_attach = function(client, bufnr)
								-- Enable formatting via ESLint
								vim.api.nvim_create_autocmd("BufWritePre", {
									buffer = bufnr,
									command = "EslintFixAll",
								})
							end,
							settings = {
								workingDirectories = { mode = "auto" },
							},
						})
					end,
					["cssls"] = function()
						lspconfig.cssls.setup({
							capabilities = capabilities,
							settings = {
								css = { lint = { unknownAtRules = "ignore" } },
							},
						})
					end,
					["tailwindcss"] = function()
						lspconfig.tailwindcss.setup({
							capabilities = capabilities,
							settings = {
								tailwindCSS = {
									experimental = {
										classRegex = {
											{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
											{ "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
										},
									},
								},
							},
						})
					end,
					["lua_ls"] = function()
						lspconfig.lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									telemetry = { enable = false },
									diagnostics = { globals = { "vim" } },
									workspace = {
										checkThirdParty = false,
										library = {
											[vim.fn.expand("$VIMRUNTIME/lua")] = true,
											[vim.fn.stdpath("config") .. "/lua"] = true,
										},
									},
								},
							},
						})
					end,
					["emmet_ls"] = function()
						lspconfig.emmet_ls.setup({
							capabilities = capabilities,
							filetypes = {
								"html",
								"typescriptreact",
								"javascriptreact",
								"css",
								"sass",
								"scss",
								"less",
								"svelte",
							},
						})
					end,
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			{ "antosha417/nvim-lsp-file-operations", config = true },
		},
		config = function()
			-- Configure diagnostics globally
			vim.diagnostic.config({
				virtual_text = {
					source = true,
					severity = {
						min = vim.diagnostic.severity.HINT,
					},
				},
				float = {
					source = true,
					border = "rounded",
				},
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			-- Diagnostic highlights are handled by the theme system in lua/theme/highlights.lua
			-- No need to set them here as they're already defined with proper theme colors

			-- Debug command to check diagnostic severity
			vim.api.nvim_create_user_command("DiagnosticInfo", function()
				local diagnostics = vim.diagnostic.get(0)
				for _, d in ipairs(diagnostics) do
					local severity_name = vim.diagnostic.severity[d.severity]
					print(string.format("[%s] %s (code: %s, source: %s)", severity_name, d.message:sub(1, 50), d.code or "none", d.source or "unknown"))
				end
			end, {})

			-- Disable concealing which can cause URL highlighting issues
			vim.opt.conceallevel = 0
			vim.opt.concealcursor = ""

			-- KEYMAPS
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show description" })
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
			vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open diagnostics" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "gs", ":vsplit | lua vim.lsp.buf.definition()<CR>") -- open defining buffer in vertical split
			-- vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Go to next diagnostics" })
			vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Go to prev diagnostics" })
		end,
	},
}
