# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive Neovim configuration built around **lazy.nvim** plugin management. The configuration is modular, with each plugin defined in separate files under `lua/plugins/`. The setup is optimized for web development (TypeScript/JavaScript, React, Svelte), Python development, and AI-assisted coding.

## Architecture

### Core Structure
- **Entry Point**: `init.lua` - Sets up lazy.nvim and loads core modules
- **Core Modules**: 
  - `lua/options.lua` - Neovim settings and options
  - `lua/keymaps.lua` - Custom key mappings and commands
  - `lua/utils.lua` - Utility functions for path manipulation and project detection
- **Plugin Directory**: `lua/plugins/` - Individual plugin configurations
- **External Dependencies**: `~/.config/colorscheme/` - Custom Rose Pine theme

### Plugin Management
All plugins use **lazy.nvim** with event-based loading for performance. Key loading patterns:
- `BufReadPre`/`BufNewFile` for file-related plugins
- `VeryLazy` for non-critical plugins
- Key-based loading for interactive features
- Priority system for essential components (colorscheme, UI)

## Key Configurations

### LSP Setup (`lua/plugins/lsp-config.lua`)
- **Mason ecosystem**: Auto-installs LSP servers for TypeScript, HTML, CSS, Tailwind, Lua, Python, etc.
- **Custom diagnostics**: Enhanced styling with custom highlights
- **Special configurations**: TypeScript filtering, Tailwind CSS support

### AI Integration
- **99**: ThePrimeagen's AI agent plugin for inline code editing (via opencode)
- **AI Tracker**: Custom local plugin for tracking AI-made file changes

### File Management
- **Neo-tree**: Primary file explorer (Leader+e)
- **Mini.files**: Alternative browser with preview (Leader+E)
- **Snacks Picker**: Fuzzy finding for files, grep, buffers (Leader+f, Leader+/)

### Git Integration
- **Gitsigns**: Git changes in gutter
- **Snacks Git**: LazyGit integration, blame, browsing (Leader+gg, Leader+gb)

## Important Keymaps

### Core Navigation
- `<leader>` = Space key
- `<C-h/j/k/l>` - Window navigation (works with TMux)
- `<leader>sv/sh` - Split vertically/horizontally
- `<C-x>` - Close current split

### File Operations
- `<leader>f` - Fuzzy find files
- `<leader>/` - Fuzzy search in current buffer
- `<leader>e` - Toggle Neo-tree
- `<leader>E` - Toggle Mini.files
- `<C-g><C-g>` - AI Tracker: Show changes by file

### AI & Code Actions
- `<C-g>f` - 99: Fill in function
- `<C-g>v` - 99: Visual selection action
- `<C-g>s` - 99: Stop all requests
- `<C-g><C-g>` - AI Tracker: Show changes by file
- `<C-g>j/k` - AI Tracker: Next/prev change
- FastAction integration for quick code actions

### Development Tools
- `<leader>gg` - LazyGit
- `<leader>gb` - Git blame
- `SR` - Search and replace word under cursor
- `<leader>rc` - Reload colorscheme

### Custom Commands
- `:HSL` - Convert CSS hsl() to ShadCN format
- `:ToHSL` - Reverse HSL conversion
- `:ReloadColors` - Reload colorscheme and UI components

## Theme System

**Rose Pine** colorscheme with:
- Dynamic light/dark mode switching via `auto-dark-mode.nvim`
- Transparent background support
- Custom diagnostic and UI highlights
- Lualine integration with project detection

## Development Workflow

### Formatting & Linting
- **Conform.nvim**: Prettier (auto-detected config), Stylua, Black
- **nvim-lint**: ESLint for JavaScript/TypeScript
- Format on save enabled

### Session Management
- **Auto-session**: Automatic session restoration per directory
- **Snacks Dashboard**: Custom dashboard on startup

### Terminal Integration
- **Floaterm**: Floating terminal management
- **TMux Navigator**: Seamless pane navigation
- **Snacks Terminal**: Advanced terminal handling

## Special Features

### Text Manipulation
- Auto-indenting paste operations
- Smart commenting via Mini.comment
- Surround text manipulation via Mini.surround
- Enhanced text objects via Mini.ai

### UI Enhancements
- **Noice**: Enhanced messages, cmdline, and popups
- **Dressing**: Better vim.ui.select/input interfaces
- **Lualine**: Comprehensive status line with macro recording, git status, project detection

### Project Detection
The configuration includes sophisticated project root detection via `utils.lua` that finds project roots based on common markers (`.git`, `package.json`, etc.) for proper LSP and tool integration.

## File Patterns

When working with this configuration:
- Plugin files follow the pattern: single plugin per file in `lua/plugins/`
- Each plugin file returns a lazy.nvim specification table
- Keymaps are centralized in `lua/keymaps.lua` unless plugin-specific
- Use existing utility functions in `lua/utils.lua` for path operations

## External Dependencies

- **Colorscheme**: Located at `~/.config/colorscheme/lua/rose-pine/`
- **TMux integration**: Expects TMux for navigator functionality
- **System tools**: Prettier, ESLint, Python formatters expected in PATH