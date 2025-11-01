# AI Tracker - Quick Start Guide

## ✅ Installation Complete!

Your AI Changes Tracker is now fully installed and ready to use.

## 🗂️ What Was Created

### OpenCode Plugin
- **Location:** `~/.config/opencode/plugin/file-tracker.js`
- **Purpose:** Automatically captures file changes when using OpenCode

### Neovim Plugin
- **Location:** `~/.config/nvim/lua/ai-tracker/`
- **Files:**
  - `init.lua` - Main module
  - `picker.lua` - Snacks picker integration
  - `utils.lua` - Helper functions
  - `README.md` - Full documentation
- **Config:** `~/.config/nvim/lua/plugins/ai-tracker.lua`

### Data Storage
- **Location:** `~/.local/share/nvim/ai-changes.jsonl`
- **Format:** JSONL (one JSON object per line)

## 🚀 How to Use

### 1. Restart Neovim

For the plugin to load:
```bash
# Close Neovim and reopen
```

### 2. Use OpenCode to Make Changes

When you use OpenCode to modify files, changes are automatically tracked!

Example:
```bash
# Start OpenCode
opencode

# Ask it to make changes
> Add error handling to the user service
```

### 3. View Changes in Neovim

**Show all AI changes:**
```
:AITracker
```
or press `<leader>ai` (Space + a + i)

**Show changes for current file:**
```
:AITrackerFile
```
or press `<leader>af`

**Navigate through changes:**
- `]a` - Jump to next AI change
- `[a` - Jump to previous AI change

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `:AITracker` | Show all AI changes |
| `:AITrackerFile` | Show changes for current file |
| `:AITrackerGrouped` | Show changes grouped by prompt |
| `:AIPrompt <text>` | Manually annotate next changes |
| `:AITrackerReload` | Reload changes from log |
| `:AITrackerClear` | Clear all tracked changes |

## ⌨️ Keybindings

| Key | Action |
|-----|--------|
| `<leader>ai` | Show all AI changes |
| `<leader>af` | Show changes for current file |
| `<leader>ag` | Show grouped by prompt |
| `<leader>ap` | Annotate AI prompt |
| `]a` | Next AI change |
| `[a` | Previous AI change |

## 🧪 Test It Out

A test entry has been created. Try viewing it:

1. Open Neovim
2. Press `<leader>ai` (or type `:AITracker`)
3. You should see a test entry with "Create AI tracker plugin"

## 🔍 Troubleshooting

### OpenCode not tracking changes?

Check if the plugin file exists:
```bash
ls ~/.config/opencode/plugin/file-tracker.js
```

If it exists, restart OpenCode and try again.

### No changes showing in picker?

1. Check the log file:
```bash
cat ~/.local/share/nvim/ai-changes.jsonl
```

2. Reload in Neovim:
```
:AITrackerReload
```

### Plugin not loading in Neovim?

1. Check for errors:
```
:messages
```

2. Verify Snacks.nvim is installed:
```
:Lazy
```

## 📖 Full Documentation

See `~/.config/nvim/lua/ai-tracker/README.md` for complete documentation.

## 🎯 Next Steps

1. Restart Neovim to load the plugin
2. Use OpenCode to make some changes to a file
3. Open Neovim and press `<leader>ai` to see the tracked changes
4. Navigate through changes with `]a` and `[a`

Enjoy tracking your AI-assisted changes!
