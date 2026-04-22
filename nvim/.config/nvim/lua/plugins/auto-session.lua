return {
	"rmagatti/auto-session",
	cond = function()
		return vim.env.KITTY_SCROLLBACK_NVIM ~= "true"
	end,
	config = function()
		local auto_session = require("auto-session")

		vim.opt.sessionoptions:remove("terminal")

		auto_session.setup({
			auto_restore_enabled = true,
			auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
		})

		local keymap = vim.keymap

		keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
	end,
}
