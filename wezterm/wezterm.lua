local wezterm = require("wezterm")
local config = {}

config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.font = wezterm.font("BerkeleyMono Nerd Font")
config.font_size = 19
config.max_fps = 120

config.window_background_opacity = 0.98
config.macos_window_background_blur = 100

config.color_scheme = "CustomScheme"
config.color_schemes = {
	["CustomScheme"] = {
		foreground = "#FFFFFF",
		background = "#0E0E0E",
		cursor_bg = "#D0D4E0",
		cursor_border = "#D0D4E0",
		cursor_fg = "#0E0E0E",
		selection_bg = "#545168",
		selection_fg = "#FFFFFF",
		ansi = {
			"#1E1E1E",
			"#FF995D",
			"#E2B8A0",
			"#FF995D",
			"#8A9AA6",
			"#E8A07D",
			"#C0E3F0",
			"#FFFFFF",
		},
		brights = {
			"#FFFFFF",
			"#FF995D",
			"#E2B8A0",
			"#FF995D",
			"#8A9AA6",
			"#E8A07D",
			"#C0E3F0",
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
