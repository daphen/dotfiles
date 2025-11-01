return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			-- Commented out to prevent duplicate ESLint messages
			-- TypeScript LSP already reports ESLint errors
			-- javascript = { "eslint" },
			-- typescript = { "eslint" },
			-- javascriptreact = { "eslint" },
			-- typescriptreact = { "eslint" },
			svelte = { "eslint" },
			vue = { "eslint" },
		}

		-- Add back LintInfo command
		vim.api.nvim_create_user_command("LintInfo", function()
			local ft = vim.bo.filetype
			local linters = lint.linters_by_ft[ft] or {}
			print("Current filetype: " .. ft)
			print("Configured linters: " .. vim.inspect(linters))
		end, {})

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>L", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
