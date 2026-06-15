return {
	"nvim-lspconfig",
	event = "VimEnter",  -- Load after session restoration to avoid LSP flood
	after = function()
		-- Servers come from nix (extraPackages), not mason. mason-lspconfig
		-- v2 only auto-enables mason-installed servers, so enable explicitly.
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		-- nvim implements LSP file-watching with a synchronous tree walk
		-- (vim._watch.watchdirs, no inotifywait) — froze nvim ~15s on every
		-- monorepo start. Servers watch their own files.
		capabilities.workspace = vim.tbl_deep_extend("force", capabilities.workspace or {}, {
			didChangeWatchedFiles = { dynamicRegistration = false },
		})
		vim.lsp.config("*", { capabilities = capabilities })

		-- The CLI serves LSP via --lsp; no oxc_language_server binary exists.
		vim.lsp.config("oxlint", {
			cmd = { "oxlint", "--lsp" },
		})

		local eslint_configs = {
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
		}
		local base_eslint_attach = vim.lsp.config.eslint and vim.lsp.config.eslint.on_attach
		vim.lsp.config("eslint", {
			-- Attach only where there's an eslint config AND eslint is
			-- actually installed. The lovable monorepo lints with oxlint
			-- and has stray eslint.config.mjs files but no eslint package,
			-- which otherwise spams "Unable to find ESLint library".
			root_dir = function(bufnr, on_dir)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				local cfg = vim.fs.find(eslint_configs, { path = fname, upward = true })[1]
				if not cfg then return end
				local dir = vim.fs.dirname(cfg)
				if not vim.fs.find("node_modules/eslint", { path = dir, upward = true })[1] then
					return
				end
				on_dir(dir)
			end,
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
							if diagnostic.source == "eslint" then
								return false
							end
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
						},
					},
				},
			},
		})

		-- Lovable essentials: always on (lean sandbox set).
		local servers = { "ts_ls", "eslint", "oxlint", "html", "tailwindcss", "gopls", "nil_ls", "lua_ls" }
		-- Full profile (nvim-next on the desktop): extras we use locally but
		-- don't want in sandboxes. The wrapper sets NVIM_PROFILE=full and puts
		-- the matching server binaries on PATH.
		if vim.env.NVIM_PROFILE == "full" then
			vim.list_extend(servers, { "pyright" })
		end
		vim.lsp.enable(servers)

		-- Global float border (0.12-native). Replaces the deprecated
		-- vim.lsp.with(handlers.hover/signature_help, {border}) — covers
		-- hover, signature help, and diagnostics floats in one setting.
		vim.o.winborder = "rounded"

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
}
