return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
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
					"volar",
					"glint",
				},
				automatic_installation = true,
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
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = cmp_nvim_lsp.default_capabilities()

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
    ]])

			local border = {
				{ "╭", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╮", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "╯", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╰", "FloatBorder" },
				{ "│", "FloatBorder" },
			}

			local on_attach = function(client, bufnr)
				vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
					border = border,
				})
				vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
					border = border,
				})
			end

			-- Server Configurations
			local servers = {
				html = { filetypes = { "hbs" } },
				ts_ls = {
					handlers = {
						["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
							result.diagnostics = vim.tbl_filter(function(diagnostic)
								local code = diagnostic.code
								return code ~= 6133 and code ~= 6196 and code ~= 6198 and code ~= 6192
							end, result.diagnostics)
							vim.lsp.handlers["textDocument/publishDiagnostics"](_, result, ctx, config)
						end,
					},
				},
				cssls = {
					settings = {
						css = { lint = { unknownAtRules = "ignore" } },
					},
				},
				tailwindcss = {
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
				},
				lua_ls = {
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
				},
				emmet_ls = {
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
				},
			}

			-- Setup all servers
			for server, config in pairs(servers) do
				lspconfig[server].setup(vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, config or {}))
			end

			-- Simple server setups
			local simple_servers = { "volar", "pylsp", "svelte", "glint" }
			for _, server in ipairs(simple_servers) do
				lspconfig[server].setup({
					capabilities = capabilities,
					on_attach = on_attach,
				})
			end

			-- KEYMAPS
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show description" })
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to definition" })
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
			vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open diagnostics" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "gs", ":vsplit | lua vim.lsp.buf.definition()<CR>") -- open defining buffer in vertical split
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "[d", vim.diagnostic.goto_next, { desc = "Go to next diagnostics" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, { desc = "Go to prev diagnostics" })
		end,
	},
}
