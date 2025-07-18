# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive dotfiles configuration repository that manages development environment settings across multiple tools. The configuration is centered around a unified theme system (Rose Pine) with seamless integration between terminal, editor, shell, and productivity tools.

## Architecture

### Core Components

1. **Neovim Configuration** (`/nvim/`)
   - Lazy.nvim plugin management with modular plugin structure
   - AI-integrated development with Avante.nvim (Claude Sonnet 4) and Supermaven
   - Comprehensive LSP setup with Mason ecosystem
   - Custom theme system with automatic light/dark switching

2. **Fish Shell Configuration** (`/fish/`)
   - Fisher plugin manager for shell enhancements
   - Custom theme switching functions coordinated with system preferences
   - Tide prompt with project detection and git integration
   - Vi key bindings and fzf integration

3. **Tmux Configuration** (`/tmux/`)
   - TPM plugin manager with vim-tmux-navigator
   - Custom prefix key (C-s) with Rose Pine theming
   - Session management integrated with Sesh
   - Floating terminal support via tmux-floax

4. **Terminal Emulator** (`/ghostty/`)
   - Ghostty terminal with BerkeleyMono Nerd Font
   - Dynamic theme switching (light/dark)
   - Custom key bindings for tmux integration
   - Hidden macOS titlebar for clean interface

5. **Productivity Tools**
   - **Raycast** (`/raycast/`): Extensive TypeScript-based extensions for Spotify, Arc, colors, downloads, 1Password, and Slack
   - **SketchyBar** (`/sketchybar/`): Custom macOS menu bar with battery, clock, volume, and DND indicators
   - **Sesh** (`/sesh/`): Advanced session management with predefined project sessions

### Theme System Integration

The configuration implements a unified theming approach:
- **Rose Pine** as the base colorscheme across all tools
- **Automatic theme detection** via system preferences
- **Coordinated switching** between light and dark modes
- **Custom theme functions** in Fish shell (`toggle_theme.fish`, `theme.fish`)

### Development Workflow Integration

- **Seamless navigation** between tmux panes and vim splits via vim-tmux-navigator
- **Session management** with Sesh providing quick project switching
- **AI-assisted development** with Claude Sonnet 4 integration in Neovim
- **Quick terminal access** via Ghostty floating terminals
- **Productivity enhancement** through Raycast extensions

## Key Configuration Files

### Essential Files to Understand
- `nvim/init.lua` - Neovim entry point with lazy.nvim setup
- `fish/config.fish` - Shell configuration with abbreviations and paths
- `tmux/tmux.conf` - Terminal multiplexer setup with custom bindings
- `ghostty/config` - Terminal emulator configuration
- `sesh/sesh.toml` - Session management with predefined projects

### Plugin Management
- **Neovim**: `lazy.nvim` with plugins in `nvim/lua/plugins/`
- **Fish**: `fisher` with plugin list in `fish/fish_plugins`
- **Tmux**: `tpm` with plugins defined in `tmux/tmux.conf`

### Theme Files
- `colorscheme/lua/rose-pine/` - Custom Rose Pine theme fork
- `ghostty/themes/` - Terminal light/dark themes
- `fish/functions/set_*_theme.fish` - Theme switching functions

## Development Commands

### Theme Management
```bash
# Toggle between light and dark themes
toggle_theme

# Set specific theme
set_light_theme
set_dark_theme

# Reload colorscheme in Neovim
:ReloadColors
```

### Session Management
```bash
# Start Sesh session manager
sesh

# Create new tmux session
tmux new-session -s <name>

# List sessions
tmux list-sessions
```

### Fish Shell Commands
```bash
# Reload Fish configuration
source ~/.config/fish/config.fish

# Clean Neovim swap files
clean_nvim_swap

# Update Fish plugins
fisher update
```

### Raycast Extensions
- Extensions are TypeScript-based with individual build processes
- Located in `raycast/extensions/` with UUID-based directories
- Each extension has its own `package.json` and build system

## Key Bindings

### Tmux (Prefix: C-s)
- `C-s c` - New window
- `C-s v` - Split vertically
- `C-s h` - Split horizontally
- `C-s x` - Close pane
- `C-h/j/k/l` - Navigate panes (vim-tmux-navigator)

### Ghostty Terminal
- `Cmd+K` - Previous session
- `Cmd+L` - Next session
- `Cmd+E` - Toggle floating terminal

### Neovim (Leader: Space)
- `<leader>aa` - Avante ask (Claude integration)
- `<leader>f` - Fuzzy find files
- `<leader>gg` - LazyGit
- `<leader>e` - Toggle Neo-tree
- `<leader>rc` - Reload colorscheme

## Integration Points

### Vim-Tmux Navigation
- Seamless navigation between vim splits and tmux panes
- Consistent `C-h/j/k/l` bindings across both tools
- Requires `vim-tmux-navigator` plugin in both vim and tmux

### Theme Coordination
- Fish functions trigger theme changes across all tools
- Neovim auto-dark-mode syncs with system preferences
- Ghostty themes switch via configuration includes

### Session Management
- Sesh provides project-based session templates
- Integrates with tmux for session creation and switching
- Predefined sessions for common projects (SiS, Claude, Nvim, etc.)

## Special Features

### AI Integration
- **Avante.nvim** with Claude Sonnet 4 (temperature 0, 32k tokens)
- **Supermaven** for AI-powered code completion
- **Claude Code** official CLI integration

### Custom Commands
- `:HSL` - Convert CSS hsl() to ShadCN format
- `:ToHSL` - Reverse HSL conversion
- `:ReloadColors` - Reload colorscheme and UI components

### Productivity Extensions
- Comprehensive Raycast extensions for system control
- Spotify integration with full playback control
- Arc browser management and tab switching
- Color picker and management tools
- Downloads management and quick access

## File Structure Conventions

### Configuration Organization
- Each tool has its own directory in the root
- Plugin configurations are modular (especially Neovim)
- Theme files are centralized in `colorscheme/`
- Custom functions are in `fish/functions/`

### Neovim Plugin Structure
- One plugin per file in `lua/plugins/`
- Lazy.nvim specification tables
- Event-based loading for performance
- Centralized keymaps in `lua/keymaps.lua`

This configuration represents a highly integrated development environment optimized for productivity, with consistent theming, efficient navigation, and comprehensive tool integration.