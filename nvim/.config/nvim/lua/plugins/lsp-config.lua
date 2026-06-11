return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = { "Mason", "MasonUpdate", "MasonInstall", "MasonUninstall" },
		lazy = true, -- Only load on command to avoid startup overhead
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
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		event = "VeryLazy", -- Load after session restoration so servers register on every startup
		config = function()
			-- mason-lspconfig v2 auto-enables installed servers via
			-- vim.lsp.enable and ignores the old setup handlers entirely —
			-- ALL server config must go through vim.lsp.config.
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- nvim implements LSP file-watching with a synchronous tree walk
			-- (vim._watch.watchdirs, no inotifywait installed) — froze nvim
			-- ~15s on every monorepo start. Servers watch their own files.
			capabilities.workspace = vim.tbl_deep_extend("force", capabilities.workspace or {}, {
				didChangeWatchedFiles = { dynamicRegistration = false },
			})
			vim.lsp.config("*", { capabilities = capabilities })

			-- lspconfig's default cmd is `oxc_language_server`, a binary
			-- neither mason nor npm ship; the CLI serves LSP via --lsp.
			vim.lsp.config("oxlint", {
				cmd = { "oxlint", "--lsp" },
			})

			local base_eslint_attach = vim.lsp.config.eslint and vim.lsp.config.eslint.on_attach
			vim.lsp.config("eslint", {
				-- Only attach in projects with an actual eslint config —
				-- default root matches any package.json.
				root_markers = {
					".eslintrc",
					".eslintrc.js",
					".eslintrc.cjs",
					".eslintrc.json",
					".eslintrc.yml",
					".eslintrc.yaml",
					"eslint.config.js",
					"eslint.config.cjs",
					"eslint.config.mjs",
					"eslint.config.ts",
				},
				on_attach = function(client, bufnr)
					if base_eslint_attach then
						base_eslint_attach(client, bufnr)
					end
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						command = "LspEslintFixAll",
					})
				end,
				settings = {
					workingDirectories = { mode = "auto" },
				},
			})

			vim.lsp.config("html", {
				filetypes = { "hbs" },
			})

			-- Files not covered by any project tsconfig (.agents/, go/_embedded_runtime/, …)
			-- fall back to the monorepo's stray root template (nodenext +
			-- verbatimModuleSyntax) and drown in bogus TS1287s. CI never
			-- typechecks them — their diagnostics are pure noise.
			local uncovered_cache = {}
			local function tsconfig_uncovered(fname)
				local dir = vim.fs.dirname(fname)
				if uncovered_cache[dir] ~= nil then return uncovered_cache[dir] end
				local found = vim.fs.find("tsconfig.json", { path = dir, upward = true })[1]
				local repo = vim.fs.root(dir, ".git")
				local res = found ~= nil and repo ~= nil
					and found == vim.fs.joinpath(repo, "tsconfig.json")
				uncovered_cache[dir] = res
				return res
			end

			vim.lsp.config("ts_ls", {
				handlers = {
					["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
						if result and result.diagnostics then
							if result.uri and tsconfig_uncovered(vim.uri_to_fname(result.uri)) then
								result.diagnostics = {}
							end
							result.diagnostics = vim.tbl_filter(function(diagnostic)
								local code = diagnostic.code
								if type(code) == "string" then
									code = tonumber(code)
								end
								-- ESLint diagnostics come from eslint-lsp; drop ts_ls duplicates.
								if diagnostic.source == "eslint" then
									return false
								end
								-- Next.js-specific warnings (71XXX) during TanStack Start migration.
								if type(code) == "number" and code >= 71000 and code < 72000 then
									return false
								end
								return true
							end, result.diagnostics)
						end
						vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
					end,
				},
			})

			vim.lsp.config("tailwindcss", {
				settings = {
					tailwindCSS = {
						-- templates/ holds dozens of starter apps; scanning
						-- their tailwind configs stalls every monorepo start.
						files = {
							exclude = {
								"**/.git/**",
								"**/node_modules/**",
								"**/templates/**",
							},
						},
						experimental = {
							classRegex = {
								{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
								{ "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
							},
						},
					},
				},
			})

			vim.lsp.config("lua_ls", {
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

			vim.lsp.config("emmet_ls", {
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

			require("mason-lspconfig").setup({
				ensure_installed = {
					"ts_ls",
					"eslint",
					"oxlint",
					"html",
					-- "cssls",  -- Disabled: Tailwind v4 uses unknown at-rules
					"tailwindcss",
					"lua_ls",
					"emmet_ls",
					"svelte",
					"graphql",
					"pylsp",
					"gopls",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy", -- Load after session restoration to avoid LSP flood
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
					print(
						string.format(
							"[%s] %s (code: %s, source: %s)",
							severity_name,
							d.message:sub(1, 50),
							d.code or "none",
							d.source or "unknown"
						)
					)
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
			vim.keymap.set("n", "]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, { desc = "Go to next diagnostics" })
			vim.keymap.set("n", "[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, { desc = "Go to prev diagnostics" })
		end,
	},
}
