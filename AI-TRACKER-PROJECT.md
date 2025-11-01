# AI Changes Tracker - Project Documentation

## 🎯 Project Goal

Build a hybrid system to track file changes made by AI coding assistants (OpenCode, Claude Code, etc.) with quick navigation in Neovim.

## ✅ What Has Been Built

### 1. OpenCode Plugin (JavaScript)

**File:** `~/.config/opencode/plugin/file-tracker.js`

**What it does:**
- Hooks into OpenCode's tool execution events (`tool.execute.before` and `tool.execute.after`)
- Captures **Edit** and **Write** operations
- Logs metadata to JSONL file: `~/.local/share/nvim/ai-changes.jsonl`

**Data captured:**
- File path and line number
- User prompts/requests
- Tool type (edit/write)
- Before/after content for diffs
- Timestamps and session IDs
- Git diffs when available

**Event hooks:**
- `event` - Captures user messages/prompts
- `tool.execute.before` - Reads file content before changes
- `tool.execute.after` - Logs the change with metadata

### 2. Neovim Plugin (Lua)

**Location:** `~/.config/nvim/lua/ai-tracker/`

**Files created:**

#### `init.lua` - Main Module
- `setup()` - Initialize plugin
- `show()` - Show all AI changes in picker
- `show_file()` - Show changes for current file only
- `show_grouped()` - Group changes by prompt
- `annotate_prompt()` - Manual annotation mode
- `next()` / `prev()` - Navigate changes like git hunks
- `highlight_change()` - Temporarily highlight changed lines

#### `picker.lua` - Snacks Picker Integration
- `to_picker_items()` - Transform JSONL to picker format
- `show()` - Display in Snacks picker with custom formatting
- `show_grouped()` - Display grouped view
- `show_diff()` - Show diff in floating window

#### `utils.lua` - Helper Functions
- `parse_iso_timestamp()` - Parse ISO timestamps
- `time_ago()` - Human-readable time formatting
- `read_jsonl()` / `append_jsonl()` - JSONL file operations
- `format_path()` - Project-aware path formatting
- `get_tool_icon()` - Icons for edit/write tools

#### Plugin Configuration
**File:** `~/.config/nvim/lua/plugins/ai-tracker.lua`

Lazy.nvim plugin spec with:
- Keybindings: `<leader>ai`, `<leader>af`, `<leader>ag`, `]a`, `[a`
- Commands: `:AITracker`, `:AITrackerFile`, `:AIPrompt`, etc.
- Lazy loading on keys and commands

### 3. Data Storage

**Format:** JSONL (JSON Lines)
**Location:** `~/.local/share/nvim/ai-changes.jsonl`

**Entry structure:**
```json
{
  "timestamp": "2025-01-24T10:30:00Z",
  "source": "opencode",
  "tool": "edit",
  "file_path": "/path/to/file.ts",
  "line_number": 45,
  "prompt": "add error handling",
  "old_string": "...",
  "new_string": "...",
  "session_id": "uuid"
}
```

## 🎮 Features Implemented

### ✅ Automatic Tracking
- OpenCode plugin automatically captures all Edit/Write operations
- No user intervention needed
- Persistent across Neovim sessions

### ✅ Snacks Picker Integration
- Custom formatter to avoid conflicts with global Snacks formatters
- Displays: `[time ago] [project] file:line - prompt`
- File preview at exact line (currently working!)
- Navigate with `j/k`, confirm with `<Enter>`

### ✅ Navigation Commands
- `<leader>ai` - Show all changes
- `<leader>af` - Show changes for current file
- `<leader>ag` - Show grouped by prompt
- `]a` / `[a` - Jump to next/previous change in file

### ✅ Manual Annotation (Fallback)
- `:AIPrompt <text>` - Annotate next changes with prompt
- Works with any AI tool (not just OpenCode)
- Tracks via `BufWritePost` autocmd

### ✅ Hybrid Approach
- Primary: OpenCode plugin (automatic)
- Fallback: Manual annotation
- Tool agnostic storage format

## 🔧 Technical Challenges Solved

### 1. Snacks Picker Custom Formatter Conflict
**Problem:** Your existing custom `filename` formatter for monorepo support was breaking AI tracker items.

**Solution:** Modified `~/.config/nvim/lua/plugins/snacks.lua` to detect AI tracker items via `_ai_tracker` flag and bypass custom formatting for them.

### 2. Preview Not Working
**Problem:** Using custom format function disabled automatic file preview.

**Solution:** Items include all required fields (`file`, `line`, `col`, `pos`) and use custom confirm function for navigation.

### 3. Line Number Detection
**Problem:** Finding exact line where Edit tool made changes.

**Solution:** Search for `newString` content in file after change to determine line number.

### 4. Mason Network Error During Session Restore
**Problem:** Mason trying to update during auto-session restoration.

**Solution:** Added lazy loading with `event = "VeryLazy"` to Mason plugins.

## 🚀 Current Status

### Working:
- ✅ Neovim plugin loads without errors
- ✅ Picker displays items correctly
- ✅ File preview shows at correct line
- ✅ JSONL logging infrastructure
- ✅ All keybindings configured
- ✅ Time formatting (working correctly)
- ✅ Project-aware path display
- ✅ Enter key navigation (FIXED - removed custom confirm handler)
- ✅ Session view (`<leader>as`) - groups changes by session
- ✅ Prompt-to-files view (`<leader>aP`) - shows which files each prompt modified
- ✅ Multi-file change tracking support

### Issues Fixed Today:
- ✅ Enter key now correctly navigates to files instead of inserting text
- ✅ Removed problematic custom confirm handler, let Snacks handle navigation naturally
- ✅ Added new views for sessions and prompt-to-file mapping

### OpenCode Plugin Status:
- ⚠️ **Plugin NOT loading** - needs restart to test
- ✅ Updated to new plugin API (named exports, correct hooks)
- ✅ Added extensive debug logging
- ✅ Plugin files in multiple locations:
  - `~/.config/opencode/plugin/file-tracker.js`
  - `~/.opencode/plugin/file-tracker.js`
  - `~/.config/.opencode/plugin/file-tracker.js`

### Not Yet Working:
- OpenCode plugin event capturing (needs OpenCode restart)
- Automatic tracking (plugin not loading yet)

## 📋 Next Steps

### IMMEDIATE ACTION REQUIRED:

1. **Restart OpenCode to load the plugin:**
   ```bash
   # Exit OpenCode (Ctrl+C or quit)
   # Then restart it
   opencode
   ```
   
2. **Look for these console messages:**
   - `[AI Tracker] Plugin initialized for project: ...`
   - `[AI Tracker] Event: ...` (when you type)
   - `[AI Tracker] Tool before/after: ...` (when files change)
   
3. **If plugin loads successfully:**
   - Make any file change with OpenCode
   - Check log: `tail -f ~/.local/share/nvim/ai-changes.jsonl`
   - New entries should appear with correct timestamps
   - Open Neovim and use:
     - `<leader>ai` - View all changes
     - `<leader>as` - View by session
     - `<leader>aP` - View prompts and their files
     - `<leader>ag` - View grouped by prompt
     - `<leader>af` - View current file only
     - `]a` / `[a` - Navigate between changes

4. **If plugin doesn't load:**
   - Check if OpenCode shows any error messages
   - Try moving plugin to project-specific `.opencode/plugin/` directory
   - Check OpenCode documentation for plugin loading requirements

### What's New in This Session:

1. **Fixed Enter Key Navigation:**
   - Removed problematic `confirm` function from picker
   - Now uses Snacks' default file navigation
   - Enter key properly opens files at the correct line

2. **Added Session Management:**
   - `<leader>as` / `:AITrackerSessions` - View changes grouped by session ID
   - Shows how many files were changed in each session
   - Perfect for reviewing all changes from a single AI session

3. **Added Prompt-to-Files Mapping:**
   - `<leader>aP` / `:AITrackerPromptFiles` - See which files each prompt modified
   - Hierarchical view with files indented under prompts
   - Helps understand the scope of changes from each request

4. **Updated OpenCode Plugin:**
   - Rewrote with new plugin API syntax (named exports)
   - Uses correct hooks: `tool.execute.before`, `tool.execute.after`
   - Added extensive debug logging with `[AI Tracker]` prefix
   - Properly captures user prompts from message events

### Known Issues to Fix:

1. **OpenCode Plugin Not Loading**
   - Plugin written with correct new API
   - Needs OpenCode restart to test
   - May need to be in project-specific `.opencode/plugin/` directory

2. **Test Data Has Wrong Timestamps**
   - Old test entries show "39 weeks ago" (from January 2025)
   - Today is October 24, 2025
   - Real entries will have correct timestamps once plugin works

### Future Enhancements:

- [ ] Virtual text showing AI changes inline
- [ ] Integration with undo history
- [ ] Export changes to markdown report
- [ ] Support for Claude Code hooks
- [ ] Support for Cursor
- [ ] Session-based filtering
- [ ] Diff view improvements

## 🔍 Debugging Guide

### If OpenCode isn't tracking:

1. Check plugin file exists:
   ```bash
   ls ~/.config/opencode/plugin/file-tracker.js
   ```

2. Check for JavaScript errors:
   ```bash
   node --check ~/.config/opencode/plugin/file-tracker.js
   ```

3. Add debug logging to OpenCode plugin:
   ```javascript
   console.log('File tracker loaded!');
   ```

4. Restart OpenCode and check console output

### If Neovim picker is empty:

1. Check log file:
   ```bash
   cat ~/.local/share/nvim/ai-changes.jsonl
   ```

2. Check for Lua errors:
   ```vim
   :messages
   ```

3. Reload plugin:
   ```vim
   :AITrackerReload
   ```

### If preview doesn't work:

1. Verify file paths are absolute
2. Check file is readable: `ls -l <file>`
3. Try manual edit: `:edit <file>`

## 📁 File Structure

```
~/.config/
├── opencode/
│   └── plugin/
│       └── file-tracker.js          # OpenCode plugin
├── nvim/
│   └── lua/
│       ├── ai-tracker/
│       │   ├── init.lua              # Main module
│       │   ├── picker.lua            # Snacks integration
│       │   ├── utils.lua             # Helper functions
│       │   └── README.md             # Full documentation
│       └── plugins/
│           ├── ai-tracker.lua        # Lazy.nvim config
│           └── snacks.lua            # Modified for AI tracker
└── .local/share/nvim/
    └── ai-changes.jsonl              # Data storage
```

## 🎯 Design Decisions

1. **JSONL over SQLite:** Simpler, easier to debug, human-readable
2. **Hybrid approach:** Automatic when possible, manual fallback
3. **Snacks over Telescope:** Already in your config, consistent UX
4. **Custom formatter:** Avoids conflicts with your monorepo setup
5. **Line-based navigation:** Like git hunks (`]c`, `[c`)

## 📚 Resources

- OpenCode Plugin Docs: https://opencode.ai/docs/plugins/
- Snacks Picker Docs: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
- Full plugin README: `~/.config/nvim/lua/ai-tracker/README.md`
- Quick start guide: `~/.config/QUICKSTART-AI-TRACKER.md`

## 🤝 Switching to OpenCode Development

You can now use OpenCode to continue developing this plugin! The system is designed to track its own changes, so you'll be able to see how OpenCode modifies the code.

To continue development with OpenCode:

1. Start OpenCode in your config directory
2. Ask it to make improvements (e.g., "add syntax highlighting to diff view")
3. Check `:AITracker` to see what it changed
4. The plugin will track its own development!

---

**Status:** Neovim plugin fully working, OpenCode plugin needs restart to test
**Last Updated:** 2025-10-24
**Session Summary:**
- Fixed Enter key navigation issue in picker
- Added session and prompt-to-files views  
- Updated OpenCode plugin to new API syntax
- Ready for testing after OpenCode restart
