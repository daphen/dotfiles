return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonUpdate", "MasonInstall", "MasonUninstall" },
		lazy = true,  -- Only load on command to avoid startup overhead
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
		lazy = true,  -- LSP config will trigger loading when needed
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = cmp_nvim_lsp.default_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = {
					"ts_ls",
					"eslint",
					"html",
					-- "cssls",  -- Disabled: Tailwind v4 uses unknown at-rules
					"tailwindcss",
					"lua_ls",
					"emmet_ls",
					"svelte",
					"graphql",
					"pylsp",
				},
				automatic_installation = false,  -- Disabled to prevent cssls auto-install
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
									-- Filter diagnostics
									if result.diagnostics then
										result.diagnostics = vim.tbl_filter(function(diagnostic)
											local code = diagnostic.code
											
											-- Convert string codes to numbers if needed
											if type(code) == "string" then
												code = tonumber(code)
											end
											
											-- Filter ESLint diagnostics from ts_ls to prevent duplicates
											if diagnostic.source == "eslint" then
												return false
											end
											
											-- Filter all Next.js-specific warnings (71XXX codes) during TanStack Start migration
											if type(code) == "number" and code >= 71000 and code < 72000 then
												return false
											end
											
											return true
										end, result.diagnostics)
									end

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
				-- cssls disabled - Tailwind v4 uses unknown at-rules that cause warnings
				-- ["cssls"] = function()
				-- 	lspconfig.cssls.setup({
				-- 		capabilities = capabilities,
				-- 		settings = {
				-- 			css = {
				-- 				validate = false,
				-- 			},
				-- 			scss = {
				-- 				validate = false,
				-- 			},
				-- 			less = {
				-- 				validate = false,
				-- 			},
				-- 		},
				-- 	})
				-- end,
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
		event = "VeryLazy",  -- Load after session restoration to avoid LSP flood
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			{ "antosha417/nvim-lsp-file-operations", config = true },
		},
		config = function()
			-- Configure LSP floating window borders globally
			local border = "rounded"
			
			-- Override the default open_floating_preview function to always use borders
			local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts = opts or {}
				opts.border = opts.border or border
				return orig_util_open_floating_preview(contents, syntax, opts, ...)
			end
			
			-- Also set handlers explicitly
			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
				border = border,
			})
			vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
				border = border,
			})
			
			-- Filter out CSS unknownAtRules and Next.js diagnostics globally
			local orig_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
			vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
				if result and result.diagnostics then
					result.diagnostics = vim.tbl_filter(function(d)
						local code = d.code
						
						-- Convert string codes to numbers if needed
						if type(code) == "string" then
							code = tonumber(code)
						end
						
						-- Filter out Tailwind CSS at-rules warnings
						if d.code == "unknownAtRules" and d.source == "css" then
							return false
						end
						
						-- Filter all Next.js-specific warnings (71XXX codes) during TanStack Start migration
						if type(code) == "number" and code >= 71000 and code < 72000 then
							return false
						end
						
						return true
					end, result.diagnostics)
				end
				orig_handler(err, result, ctx, config)
			end

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

			-- Disable concealing which can cause URL highlighting issues (except for markdown)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function()
					if vim.bo.filetype ~= "markdown" then
						vim.opt_local.conceallevel = 0
						vim.opt_local.concealcursor = ""
					end
				end,
			})

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
