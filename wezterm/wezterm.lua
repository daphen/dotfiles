local wezterm = require("wezterm")
local config = {}

config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.font = wezterm.font("BerkeleyMono Nerd Font")
config.font_size = 21

config.color_scheme = "rose-pine"

config.window_background_opacity = 0.93
config.macos_window_background_blur = 100

config.colors = {
	background = "#161616",
	cursor_bg = "#00fba6",
	cursor_fg = "black",
}

config.scrollback_lines = 10000
config.enable_scroll_bar = true

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
