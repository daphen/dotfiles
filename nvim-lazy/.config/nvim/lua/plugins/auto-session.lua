return {
	"rmagatti/auto-session",
	cond = function()
		return vim.env.KITTY_SCROLLBACK_NVIM ~= "true"
	end,
	config = function()
		local auto_session = require("auto-session")

		vim.opt.sessionoptions:remove("terminal")
		-- Drop buffer list from sessions. Restoring 10+ files in a TS
		-- monorepo triggers a serial LSP-attach storm (10s+ blank
		-- screen). Layout/cwd/folds still restore.
		vim.opt.sessionoptions:remove("buffers")

		auto_session.setup({
			auto_restore_enabled = true,
			auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
			-- :mksession writes `doautoall SessionLoadPre` on line 4, but
			-- SessionLoadPre isn't a real Neovim event — restore retries
			-- silently with continue_restore_on_error, so swallow the noise.
			restore_error_handler = function(error_msg)
				if error_msg and error_msg:find("E216", 1, true) and error_msg:find("SessionLoadPre", 1, true) then
					return true
				end
				return auto_session.default_restore_error_handler(error_msg)
			end,
		})

		local keymap = vim.keymap

		keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
	end,
}
