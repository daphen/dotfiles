return {
	"brenoprata10/nvim-highlight-colors",
	config = function()
		require("nvim-highlight-colors").setup({
			---Render style
			---@usage 'background'|'foreground'|'virtual'
			render = "virtual",
			virtual_symbol = "●",
			enable_named_colors = true,
			enable_hsl = true,
			enable_short_hex = true,
			enable_var_usage = true,
			enable_tailwind = true,
		})
	end,
}
