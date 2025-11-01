# AI Tracker

Track AI-generated file changes with quick navigation in Neovim.

## Overview

This plugin tracks file changes made by AI coding assistants (OpenCode, Claude Code, etc.) and provides a convenient interface to review, navigate, and understand what changes were made in response to which prompts.

## Features

- **Automatic tracking** via OpenCode plugin integration
- **Manual annotation** for other AI tools
- **Quick navigation** with `]a`/`[a` keybindings
- **File preview** at exact change locations using Snacks picker
- **Grouped view** by prompts
- **Persistent storage** in JSONL format

## Architecture

### Two-Part System

1. **OpenCode Plugin** (`~/.config/opencode/plugin/file-tracker.js`)
   - Hooks into OpenCode's tool execution events
   - Captures Write/Edit operations
   - Logs to JSONL file

2. **Neovim Plugin** (`~/.config/nvim/lua/ai-tracker/`)
   - Reads JSONL log
   - Displays in Snacks picker
   - Provides navigation commands

## Installation

Already installed! The plugin configuration is in `~/.config/nvim/lua/plugins/ai-tracker.lua`.

### Requirements

- Neovim >= 0.9.0
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- OpenCode (for automatic tracking)

## Usage

### Automatic Tracking (OpenCode)

When you use OpenCode to modify files, changes are automatically tracked. No action needed!

The OpenCode plugin will log:
- File path and line number
- Your prompt/request
- Tool used (Edit or Write)
- Before/after content (for diffs)

### View Changes

**Show all changes:**
```
:AITracker
```
or
```
<leader>ai
```

**Show changes for current file:**
```
:AITrackerFile
```
or
```
<leader>af
```

**Show grouped by prompt:**
```
:AITrackerGrouped
```
or
```
<leader>ag
```

### Navigate Changes

**Jump to next AI change in current file:**
```
]a
```

**Jump to previous AI change in current file:**
```
[a
```

Similar to `]c`/`[c` for git hunks!

### Manual Annotation (Fallback Mode)

For AI tools other than OpenCode:

1. Before making changes with AI, annotate your prompt:
```
:AIPrompt add error handling to user service
```

2. Make changes with your AI tool

3. File saves will be tracked with the annotated prompt

4. Stop tracking:
```
:AIPrompt
```
(Press Enter without text)

### Picker Navigation

In the Snacks picker:
- `j/k` or `<C-n>/<C-p>` - Navigate changes
- `<Enter>` - Jump to file at exact line
- `<C-v>` - Open in vertical split
- `<C-x>` - Open in horizontal split
- `q` or `<Esc>` - Close picker

### Other Commands

**Reload changes from log:**
```
:AITrackerReload
```

**Clear all tracked changes:**
```
:AITrackerClear
```

## Configuration

Default configuration in `lua/plugins/ai-tracker.lua`:

```lua
require("ai-tracker").setup({
  log_file = "~/.local/share/nvim/ai-changes.jsonl",
  max_entries = 1000,
  auto_reload = true,
})
```

## Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ai` | n | Show all AI changes |
| `<leader>af` | n | Show AI changes for current file |
| `<leader>ag` | n | Show AI changes grouped by prompt |
| `<leader>ap` | n | Annotate AI prompt (manual mode) |
| `]a` | n | Next AI change in current file |
| `[a` | n | Previous AI change in current file |

## Data Storage

Changes are stored in JSONL format at `~/.local/share/nvim/ai-changes.jsonl`.

Each entry contains:
```json
{
  "timestamp": "2025-01-24T10:30:00Z",
  "source": "opencode",
  "tool": "edit",
  "file_path": "/path/to/file.ts",
  "line_number": 45,
  "prompt": "add error handling",
  "old_string": "...",
  "new_string": "..."
}
```

## Troubleshooting

### OpenCode plugin not tracking changes

1. Check if the plugin file exists:
```bash
ls ~/.config/opencode/plugin/file-tracker.js
```

2. Restart OpenCode

3. Make a test change and check the log:
```bash
tail ~/.local/share/nvim/ai-changes.jsonl
```

### No changes showing in picker

1. Reload changes: `:AITrackerReload`
2. Check if log file exists and has content:
```bash
cat ~/.local/share/nvim/ai-changes.jsonl
```

### Neovim plugin not loading

1. Check for errors: `:messages`
2. Restart Neovim
3. Check if Snacks.nvim is installed: `:Lazy`

## Future Enhancements

Potential features to add:
- [ ] Virtual text indicators showing AI changes inline
- [ ] Integration with undo history
- [ ] Export changes to markdown report
- [ ] Diff view side-by-side comparison
- [ ] Session-based filtering
- [ ] Support for more AI tools (Claude Code hooks, Cursor, etc.)

## License

Part of your personal dotfiles configuration.
