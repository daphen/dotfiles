return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = cmp_nvim_lsp.default_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = {
					"ts_ls",
					"html",
					"cssls",
					"tailwindcss",
					"lua_ls",
					"emmet_ls",
					"svelte",
					"graphql",
					"pylsp",
					"glint",
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
									result.diagnostics = vim.tbl_filter(function(diagnostic)
										local code = diagnostic.code
										return code ~= 6133 and code ~= 6196 and code ~= 6198 and code ~= 6192
									end, result.diagnostics)
									vim.lsp.handlers["textDocument/publishDiagnostics"](_, result, ctx, config)
								end,
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

			-- Set diagnostic highlights with your preferred colors
			vim.cmd([[
    highlight DiagnosticError guifg=#ff7f33
    highlight DiagnosticWarn guifg=#E8A07D
    highlight DiagnosticHint guifg=#E8A07D

    highlight DiagnosticVirtualTextError guifg=#ff7f33
    highlight DiagnosticVirtualTextWarn guifg=#E8A07D
    highlight DiagnosticVirtualTextHint guifg=#E8A07D

    highlight DiagnosticFloatingError guifg=#ff7f33
    highlight DiagnosticFloatingWarn guifg=#E8A07D
    highlight DiagnosticFloatingHint guifg=#E8A07D

    highlight DiagnosticSignError guifg=#ff7f33
    highlight DiagnosticSignWarn guifg=#E8A07D
    highlight DiagnosticSignHint guifg=#E8A07D

    " Fix URL highlighting issues
    highlight link Underlined Normal
    highlight Underlined gui=NONE cterm=NONE
    ]])

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
