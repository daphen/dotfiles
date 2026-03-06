# Centralized Theme System

A unified theme management system that maintains consistent colors across all development tools through a single source of truth.

## Overview

This system uses a centralized `colors.json` file to generate theme configurations for multiple tools, ensuring visual consistency across your entire development environment.

### Supported Tools
- **Neovim** - Custom colorscheme with full TreeSitter and LSP support
- **Fish Shell** - Terminal colors
- **FZF** - Fuzzy finder interface colors
- **Tide** - Fish prompt framework
- **Kitty** - Terminal emulator theme
- **Ghostty** - Terminal emulator theme
- **Wezterm** - Terminal emulator theme
- **Mako** - Notification daemon
- **Waybar** - Status bar styling
- **Rofi** - Application launcher
- **Clipse** - Clipboard manager
- **spotify-player** - Spotify TUI client
- **opencode** - AI coding assistant

## Architecture

```
theme-generator/
├── colors.json          # Single source of truth for all colors
├── theme-manager.sh     # Generation and application script
├── theme-processor.py   # Template processing engine
├── theme-viewer/        # Visual theme editor webapp (Next.js)
├── templates/           # Template files with placeholders
│   ├── nvim-dark.template
│   ├── nvim-light.template
│   ├── fish.template
│   ├── fzf.template
│   ├── tide.template
│   ├── kitty.template
│   ├── ghostty.template
│   ├── wezterm.template
│   ├── mako.template
│   ├── waybar.template
│   ├── clipse.template
│   ├── spotify-player.template
│   └── opencode.template
└── generated/           # Auto-generated theme files
    ├── nvim/
    ├── fish/
    ├── fzf/
    ├── tide/
    ├── kitty/
    ├── ghostty/
    ├── wezterm/
    ├── mako/
    ├── waybar/
    ├── clipse/
    ├── spotify-player/
    └── opencode/
```

## Core Components

### 1. Colors Definition (`colors.json`)

The central configuration file containing all color definitions organized by theme mode:

```json
{
  "themes": {
    "dark": {
      "background": {
        "primary": "#181818",
        "secondary": "#1B1B1B",
        "tertiary": "#1B1B1B",
        "selection": "#282F38",
        "surface": "#1B1B1B",
        "overlay": "#292826",
        "prompt": "#323A40"
      },
      "foreground": {
        "primary": "#EDEDED",
        "secondary": "#C3C8C6",
        "muted": "#707B84",
        "subtle": "#707B84"
      },
      "accent": {
        "red": "#FF7B72",
        "orange": "#FF570D",
        "yellow": "#ff8a31",
        "green": "#97B5A6",
        "cyan": "#8A9AA6",
        "blue": "#CCD5E4",
        "purple": "#8A92A7",
        "pink": "#8A92A7"
      },
      "semantic": {
        "error": "accent.red",
        "warning": "accent.orange",
        "keyword": "accent.green",
        "string": "accent.blue",
        "cursor": "#FF570D"
      },
      "terminal": {
        "black": "background.tertiary",
        "red": "accent.red",
        "green": "accent.green"
      }
    },
    "light": {
      // Light theme definitions...
    }
  }
}
```

**Color References**: Semantic and terminal colors can reference other colors (e.g., `"error": "accent.red"`), which the processor resolves automatically.

### 2. Template System

Templates use placeholder syntax `{{path.to.color}}` to reference colors:

```lua
-- Example from nvim-dark.template
local c = {
  bg = "{{dark.background.primary}}",
  keyword = "{{dark.semantic.keyword}}",
}
```

```bash
# Example from fzf.template
--color=bg:{{background.primary}}
--color=fg:{{foreground.primary}}
```

### 3. Generation Process

The `theme-processor.py` script:
1. Reads color values from `colors.json`
2. Resolves chained references (semantic → accent → hex)
3. Replaces `{{placeholders}}` with resolved colors
4. Outputs tool-specific configuration files

## Commands

### Theme Manager Script

```bash
# Generate themes for specific mode
./theme-manager.sh generate dark
./theme-manager.sh generate light

# Apply themes for specific mode
./theme-manager.sh apply dark
./theme-manager.sh apply light

# Switch theme (generate + apply)
./theme-manager.sh switch dark
./theme-manager.sh switch light

# Toggle between light and dark
./theme-manager.sh toggle

# Auto-detect system theme
./theme-manager.sh auto

# Show status
./theme-manager.sh status

# Show help
./theme-manager.sh help
```

## Theme Toggle Flow

When you press `Super+Ctrl+T` (or your configured keybind), here's what happens:

```
┌─────────────────────────────────────────────────────────────────┐
│  Keybind (niri/sway/etc)                                        │
│  Super+Ctrl+T → ~/.config/themes/theme-manager.sh toggle        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  theme-manager.sh toggle                                        │
│  1. Read current theme from ~/.config/theme_mode                │
│  2. Write new theme ("dark" or "light") to file                 │
│  3. Generate all themes for the new mode                        │
│  4. Apply all themes                                            │
│  5. Apply system-wide settings (GTK, gsettings)                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Apply step copies generated themes to final locations:         │
│                                                                 │
│  • Neovim      → ~/.config/nvim/colors/custom-theme-{mode}.lua  │
│  • Kitty       → ~/.config/kitty/theme.conf + live reload       │
│  • Ghostty     → ~/.config/ghostty/themes/{mode}                │
│  • Wezterm     → ~/.config/wezterm/colors/{mode}.lua + touch    │
│  • Mako        → ~/.config/mako/config + makoctl reload         │
│  • Waybar      → ~/.config/waybar/style.css + SIGUSR2           │
│  • Rofi        → update @import in config.rasi                  │
│  • Clipse      → ~/.config/clipse/custom_theme.json             │
│  • spotify-player → ~/.config/spotify-player/theme.toml         │
│  • Tide        → fish -c source (prompt colors)                 │
│                                                                 │
│  System settings:                                               │
│  • GTK 3.0/4.0 → update settings.ini                            │
│  • gsettings   → color-scheme preference                        │
└─────────────────────────────────────────────────────────────────┘
                      │
                      │ (parallel - via file watchers)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Auto-updating apps (watch ~/.config/theme_mode)                │
│                                                                 │
│  • Neovim      → vim.uv file watcher re-applies colorscheme     │
│  • Fish prompt → theme_watcher.fish sources colors on prompt    │
└─────────────────────────────────────────────────────────────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `~/.config/theme_mode` | Stores current theme ("dark" or "light") |
| `~/.config/themes/theme-manager.sh` | Main theme switching script |
| `~/.config/nvim/lua/plugins/colorscheme.lua` | Neovim file watcher |
| `~/.config/fish/conf.d/theme_watcher.fish` | Fish prompt theme checker (optional) |

## Tool-Specific Integration

### Neovim

**Generated files**: `generated/nvim/dark.theme`, `generated/nvim/light.theme`

**Applied to**: `~/.config/nvim/colors/custom-theme-{dark,light}.lua`

**Features**:
- Full TreeSitter syntax highlighting
- LSP semantic token support (explicitly linked to theme colors)
- Plugin support (Telescope, Neo-tree, Lazy, Mason, GitSigns, blink.cmp, etc.)

**Setup**:

1. Run `./theme-manager.sh switch dark` and `./theme-manager.sh switch light` once to generate and apply themes (copies to `~/.config/nvim/colors/`)

2. Create `~/.config/nvim/lua/plugins/colorscheme.lua`:
```lua
return {
  {
    "nvim-lua/plenary.nvim", -- Use an existing dependency as anchor
    lazy = false,
    priority = 1000,
    config = function()
      -- Function to read theme mode from file
      local function read_theme_mode()
        local theme_file = vim.fn.expand("~/.config/theme_mode")
        local file = io.open(theme_file, "r")
        if file then
          local mode = file:read("*line")
          file:close()
          return mode == "light" and "light" or "dark"
        end
        return "dark"
      end

      -- Function to apply theme
      local function apply_theme()
        local theme_mode = read_theme_mode()
        vim.cmd.colorscheme("custom-theme-" .. theme_mode)
      end

      -- Apply initial theme
      apply_theme()

      -- Re-apply theme when LSP attaches to ensure @lsp highlights take effect
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function()
          vim.defer_fn(apply_theme, 10)
        end,
      })

      -- Watch theme_mode file for changes (live switching)
      local theme_mode_file = vim.fn.expand("~/.config/theme_mode")
      local watch_handle = vim.uv.new_fs_event()
      if watch_handle then
        watch_handle:start(theme_mode_file, {}, vim.schedule_wrap(function(err)
          if not err then
            vim.defer_fn(apply_theme, 50)
          end
        end))
      end
    end,
  },
}
```

**How it works**:
- Reads `~/.config/theme_mode` to determine current theme ("dark" or "light")
- Uses `vim.uv.new_fs_event()` to watch the file for live theme switching
- Re-applies colorscheme on `LspAttach` to ensure LSP semantic tokens use correct colors

### Fish Shell / FZF / Tide

**Generated files**: `generated/fish/{dark,light}.theme`, `generated/fzf/{dark,light}.theme`, `generated/tide/{dark,light}.theme`

- **Fish & FZF**: Themes are generated and available for fish to source
- **Tide**: Prompt colors applied via `fish -c source`

**Optional auto-switching**: The `theme_watcher.fish` in `~/.config/fish/conf.d/` can handle prompt-level switching:
- Checks `~/.config/theme_mode` on each prompt
- Sources Fish and FZF themes when mode changes

Note: Terminal colors change instantly via terminal emulator hot-reload, not Fish.

### Kitty

**Generated file**: `generated/kitty/{dark,light}.theme`

**Applied to**: `~/.config/kitty/theme.conf`

Kitty supports live theme reloading via `kitty @ set-colors`. The theme-manager automatically reloads all running Kitty instances when the theme changes.

### Wezterm

**Generated file**: `generated/wezterm/{dark,light}.theme`

**Applied to**: `~/.config/wezterm/colors/{dark,light}.lua`

Wezterm hot-reloads automatically when its config file is touched (handled by theme-manager.sh).

### Ghostty

**Generated file**: `generated/ghostty/{dark,light}.theme`

**Applied to**: `~/.config/ghostty/themes/{dark,light}`

Ghostty can auto-detect system theme via config: `theme = light:light,dark:dark`

### Mako / Waybar

**Applied to**:
- Mako: `~/.config/mako/config` (reloaded via `makoctl reload`)
- Waybar: `~/.config/waybar/style.css` (reloaded via `SIGUSR2`)

Both are automatically reloaded when applied.

### Rofi

Rofi theme switching works by updating the `@import` statement in `~/.config/rofi/config.rasi`.

Requires existing `dark.rasi` and `light.rasi` theme files in `~/.config/rofi/`.

### Clipse

**Generated file**: `generated/clipse/{dark,light}.theme`

**Applied to**: `~/.config/clipse/custom_theme.json`

Clipse clipboard manager theme is applied automatically. Restart clipse to see changes.

## Theme Editor Webapp

A visual editor for modifying theme colors with live preview.

### Running the Editor

```bash
cd theme-viewer
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Features

- **Code Preview**: See how colors look in a syntax-highlighted code block
- **Color Picker**: Click any color to edit it with HSL sliders
- **Semantic Mapping**: View and edit how semantic colors (error, warning, keyword) map to accent colors
- **Dark/Light Toggle**: Switch between theme modes
- **Save Changes**: Writes directly to `colors.json`

After saving changes in the webapp, run `./theme-manager.sh switch dark` to regenerate and apply themes.

## Workflow

### Daily Usage
```bash
# Toggle between themes
./theme-manager.sh toggle
```

### Modifying Colors

**Option 1: Visual Editor (recommended)**
```bash
cd theme-viewer && npm run dev
# Edit colors in browser, save
./theme-manager.sh switch dark
```

**Option 2: Direct Edit**
```bash
# 1. Edit colors.json
vim colors.json

# 2. Regenerate and apply
./theme-manager.sh switch dark
```

### Adding a New Tool

1. Create template in `templates/newtool.template`
2. Use `{{path.to.color}}` placeholders
3. Add apply logic to `theme-manager.sh` if needed
4. Run `./theme-manager.sh generate dark`

## Dependencies

**Required**:
- **Python 3** - For template processing
- **jq** - For JSON parsing in shell script
- **Bash** - For the theme manager script

**Optional** (theme-manager.sh gracefully skips missing tools):
- Fish shell, Neovim, Wezterm, Ghostty, Mako, Waybar, Rofi, spotify-player, etc.

## Quick Reference

| Action | Command |
|--------|---------|
| Switch to dark | `./theme-manager.sh switch dark` |
| Switch to light | `./theme-manager.sh switch light` |
| Toggle themes | `./theme-manager.sh toggle` |
| Regenerate all | `./theme-manager.sh generate` |
| Check status | `./theme-manager.sh status` |
