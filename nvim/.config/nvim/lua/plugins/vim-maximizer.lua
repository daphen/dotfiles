return {
	{
		"vim-maximizer",
		-- Ctrl+Shift+m (no Alt on the Charybdis; kitty protocol keeps it
		-- distinct from <C-m>/<CR>). Zooms a split, toggles back.
		keys = {
			{ "<C-S-m>", "<cmd>MaximizerToggle<CR>", desc = "Maximize/restore split" },
		},
	},
}
