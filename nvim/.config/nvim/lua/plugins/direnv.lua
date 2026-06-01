return {
	-- Auto-loads .envrc so LSPs pick up the devenv toolchain. Safety net
	-- for nvim launches outside a direnv-sourced shell.
	"NotAShelf/direnv.nvim",
	event = "VeryLazy",
	opts = {
		autoload_direnv = true,
		notifications = {
			silent_autoload = true, -- don't toast every .envrc load
		},
	},
}
