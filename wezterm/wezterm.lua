local wezterm = require("wezterm")
local config = {}

config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.font = wezterm.font("BerkeleyMono Nerd Font")
config.font_size = 19

config.window_background_opacity = 0.98
config.macos_window_background_blur = 100

config.color_scheme = "CustomScheme"
config.color_schemes = {
	["CustomScheme"] = {
		foreground = "#DDDDED", -- text
		background = "#161616", -- base
		cursor_bg = "#DAD1CE", -- subtle
		cursor_border = "#DAD1CE", -- subtle
		cursor_fg = "#161616", -- base
		selection_bg = "#403d52", -- highlight_med
		selection_fg = "#DDDDED", -- text

		ansi = {
			"#1E1E1E",
			"#D09D8A",
			"#D6B9A9",
			"#D9AE93",
			"#698893",
			"#CE9079",
			"#697A86",
			"#DAD1CE",
		},
		brights = {
			"#DAD1CE",
			"#D09D8A",
			"#D6B9A9",
			"#D9AE93",
			"#698893",
			"#CE9079",
			"#697A86",
			"#FFFFFF",
		},
	},
}

config.window_padding = {
	bottom = 0,
}

config.scrollback_lines = 10000
config.enable_scroll_bar = false

config.keys = {
	{
		key = "X",
		mods = "CMD|SHIFT",
		action = wezterm.action.ActivateCopyMode,
	},
	{
		key = "K",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ScrollByPage(-1),
	},
	{
		key = "J",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ScrollByPage(1),
	},
}

return config
