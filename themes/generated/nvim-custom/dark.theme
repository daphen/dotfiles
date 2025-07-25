-- Custom Theme for Neovim
-- Generated from centralized theme system

local M = {}

M.colors = {
  -- Dark theme colors
  dark = {
    -- Background colors
    bg = "#0A0A0A",
    bg_secondary = "#121212",
    bg_tertiary = "#1B1B1B",
    bg_selection = "#121E42",
    bg_surface = "#121212",
    bg_overlay = "#2A2F39",
    
    -- Foreground colors
    fg = "#EDEDED",
    fg_secondary = "#D6DDEA",
    fg_muted = "#767676",
    fg_subtle = "#7E8193",
    
    -- Accent colors
    red = "#B85B53",
    orange = "#E9B872",
    yellow = "#E9B872",
    green = "#74BAA8",
    cyan = "#74BAA8",
    blue = "#6A8BE3",
    purple = "#BCB6EC",
    pink = "#A9B9EF",
    
    -- Semantic colors
    error = "#F71735",
    warning = "#FFA630",
    success = "#0EC256",
    info = "#1A8C9B",
    keyword = "#A9B9EF",
    command = "#6A8BE3",
    operator = "#b09884",
    comment = "#505050",
    string = "#74BAA8",
    
    -- Highlights
    highlight_low = "#2F2E3E",
    highlight_med = "#545168",
    highlight_high = "#6F6C85",
    
    -- Special
    cursor = "#FF570D",
    none = "NONE",
  },
  
  -- Light theme colors
  light = {
    -- Background colors
    bg = "#FDF6E3",
    bg_secondary = "#F9F2DF",
    bg_tertiary = "#FDF6E3",
    bg_selection = "#f4eeee",
    bg_surface = "#F9F2DF",
    bg_overlay = "#F9F2DF",
    
    -- Foreground colors
    fg = "#2D4A3D",
    fg_secondary = "#575279",
    fg_muted = "#9893a5",
    fg_subtle = "#8A92A7",
    
    -- Accent colors
    red = "#ED333B",
    orange = "#d7827e",
    yellow = "#69756C",
    green = "#5E7270",
    cyan = "#4A7C59",
    blue = "#286983",
    purple = "#B8713A",
    pink = "#8A92A7",
    
    -- Semantic colors
    error = "#b4637a",
    warning = "#69756C",
    success = "#5E7270",
    info = "#56949f",
    keyword = "#d7827e",
    command = "#286983",
    operator = "#56949f",
    comment = "#9893a5",
    string = "#56949f",
    
    -- Highlights
    highlight_low = "#E8EAED",
    highlight_med = "#D5D8DD",
    highlight_high = "#C2C6CC",
    
    -- Special
    cursor = "#FF570D",
    none = "NONE",
  }
}

-- Get current theme based on vim background
function M.get_colors()
  return vim.o.background == "light" and M.colors.light or M.colors.dark
end

return M