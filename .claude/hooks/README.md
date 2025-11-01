# Claude Code AI Tracker Hook

This hook provides **identical functionality** to the OpenCode AI tracker plugin, logging all Edit and Write tool executions to the same JSONL file that your Neovim plugin reads.

## 🎯 What It Does

Automatically tracks:
- ✅ **Edit operations** - File modifications with line numbers, old/new content
- ✅ **Write operations** - File writes, new file detection
- ✅ **User prompts** - Extracts from transcript for context
- ✅ **Session tracking** - Unique session IDs per Claude Code session
- ✅ **Deduplication** - Prevents duplicate entries within 1 second
- ✅ **Debug logging** - Comprehensive debug logs for troubleshooting

## 📁 Files Created

```
~/.config/.claude/
├── settings.local.json          # Updated with hook configuration
└── hooks/
    ├── ai-tracker.js            # Main hook script (identical to OpenCode plugin)
    ├── package.json             # ES module configuration
    ├── test-hook.sh             # Test script
    └── README.md                # This file
```

## 🔧 How It Works

### Architecture

```
Claude Code Edit/Write → PostToolUse Hook → ai-tracker.js → ~/.local/share/nvim/ai-changes.jsonl
                                                                              ↓
                                                                    Neovim AI Tracker Plugin
```

### Hook Configuration (settings.local.json)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.config/.claude/hooks/ai-tracker.js",
            "suppressOutput": true
          }
        ]
      }
    ]
  }
}
```

- **PostToolUse**: Fires after Edit/Write tools complete
- **matcher**: `"Edit|Write"` - Only track these tools
- **suppressOutput**: `true` - No output shown to user

### Data Flow

1. **Claude Code executes Edit/Write tool**
2. **PostToolUse hook fires** with JSON data via stdin:
   ```json
   {
     "session_id": "...",
     "transcript_path": "/path/to/transcript.jsonl",
     "tool_name": "Edit",
     "tool_input": {
       "file_path": "/absolute/path/to/file.ts",
       "old_string": "...",
       "new_string": "...",
       "replace_all": false
     },
     "tool_response": { "success": true }
   }
   ```
3. **ai-tracker.js processes** the data:
   - Extracts user prompt from transcript
   - Finds line number where change occurred
   - Deduplicates if seen recently
   - Logs to JSONL file
4. **Neovim reads** the JSONL file automatically

## 🧪 Testing

Run the test script to verify everything works:

```bash
~/.config/.claude/hooks/test-hook.sh
```

Expected output:
```
✅ Log file created successfully!

Last entry:
{
  "timestamp": "2025-10-27T20:17:00.429Z",
  "session_id": "claudecode-1761596220425-...",
  "source": "claudecode",
  "tool": "edit",
  "file_path": "/path/to/file.txt",
  "line_number": 1,
  "old_string": "old content",
  "new_string": "new content",
  "replace_all": false,
  "prompt": "Test prompt for AI tracker"
}
```

## 🔍 Debugging

### Check if hook is configured:
```bash
cat ~/.config/.claude/settings.local.json | jq .hooks
```

### View recent changes:
```bash
tail -5 ~/.local/share/nvim/ai-changes.jsonl | jq .
```

### View debug logs:
```bash
tail -20 ~/.local/share/nvim/ai-tracker-debug.log
```

### Test hook manually:
```bash
echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.txt","old_string":"old","new_string":"new"},"transcript_path":"/tmp/test.jsonl"}' | node ~/.config/.claude/hooks/ai-tracker.js
```

## 📊 Data Format

The hook writes to `~/.local/share/nvim/ai-changes.jsonl` with this structure:

### Edit Entry
```json
{
  "timestamp": "2025-10-27T20:17:00.429Z",
  "session_id": "claudecode-1761596220425-zsalhza4b",
  "source": "claudecode",
  "tool": "edit",
  "file_path": "/absolute/path/to/file.ts",
  "line_number": 42,
  "old_string": "const old = 1;",
  "new_string": "const updated = 2;",
  "replace_all": false,
  "prompt": "Update the variable name"
}
```

### Write Entry
```json
{
  "timestamp": "2025-10-27T20:17:00.429Z",
  "session_id": "claudecode-1761596220425-zsalhza4b",
  "source": "claudecode",
  "tool": "write",
  "file_path": "/absolute/path/to/new-file.ts",
  "line_number": 1,
  "is_new_file": true,
  "content_length": 1234,
  "prompt": "Create a new TypeScript file"
}
```

## 🆚 Differences from OpenCode Plugin

| Aspect | OpenCode Plugin | Claude Code Hook |
|--------|----------------|------------------|
| **Trigger** | JavaScript event handlers | PostToolUse hook via stdin |
| **Config** | `plugin/plugin.js` export | `settings.json` hook config |
| **Prompt extraction** | From `message` events | From transcript JSONL file |
| **Data source** | Event object properties | stdin JSON |
| **Implementation** | ~356 lines | ~250 lines (simpler!) |

### Functionally Identical:
- ✅ Same JSONL output format
- ✅ Same deduplication logic
- ✅ Same line number detection
- ✅ Same debug logging
- ✅ Same file validation
- ✅ Works with same Neovim plugin

## 🎮 Neovim Integration

Once the hook is working, use these commands in Neovim:

```vim
" View all Claude Code changes
<C-g><C-g>

" View changes in current file
<C-g>f

" View by session
<C-g>s

" View by prompt
<C-g>p

" Navigate changes
<C-g>j  " Next change
<C-g>k  " Previous change

" Commands
:AITracker              " Show all changes
:AITrackerFile          " Current file only
:AITrackerSessions      " By session
:AITrackerGrouped       " By prompt
```

The Neovim plugin will automatically:
- Show orange line numbers for AI-modified lines
- Display time since modification
- Group changes by file/prompt/session
- Allow navigation between changes

## ✨ Features

### Automatic Tracking
- No manual intervention needed
- Tracks every Edit/Write operation
- Persistent across sessions

### Intelligent Deduplication
- Prevents duplicate entries within 1 second
- Handles rapid successive changes
- Keeps log file clean

### Prompt Context
- Extracts user prompt from transcript
- Shows what you asked for each change
- Helps understand change rationale

### Session Management
- Unique session IDs: `claudecode-<timestamp>-<random>`
- Groups changes by AI session
- Track multi-file changes together

### Debug Logging
- Comprehensive debug logs
- Prefixed with `[CLAUDE CODE]`
- Located at: `~/.local/share/nvim/ai-tracker-debug.log`

## 🚀 Verification

After making changes with Claude Code:

1. **Check the log file:**
   ```bash
   tail -f ~/.local/share/nvim/ai-changes.jsonl
   ```

2. **Open Neovim and navigate to a changed file:**
   ```bash
   nvim <changed-file>
   ```

3. **Look for orange line numbers** on modified lines

4. **Use the picker:**
   ```vim
   <C-g><C-g>
   ```

5. **You should see entries with `source: "claudecode"`**

## 📝 Notes

- The hook runs **after** tool execution (PostToolUse)
- Prompt extraction requires a valid transcript file
- Line numbers are calculated by searching for the new content
- File paths must be absolute (validated automatically)
- The hook exits with code 0 (success, no user output)

## 🔄 Comparison with OpenCode Plugin

Both implementations are **functionally identical**:

### Same Features:
- ✅ Edit/Write tool tracking
- ✅ Line number detection
- ✅ Deduplication
- ✅ Debug logging
- ✅ Session management
- ✅ Prompt capture
- ✅ File validation

### Same Output:
Both write to the same JSONL file with identical structure, just with different `source` values:
- OpenCode: `"source": "opencode"`
- Claude Code: `"source": "claudecode"`

### Implementation Differences:
- **OpenCode**: Event-driven JavaScript plugin with inline event handlers
- **Claude Code**: Hook-driven Node.js script with stdin JSON processing

**Result**: Your Neovim plugin sees both sources as identical entries! 🎉

## 🛠️ Troubleshooting

### Hook not firing:
1. Verify settings: `cat ~/.config/.claude/settings.local.json | jq .hooks`
2. Check permissions: `ls -la ~/.config/.claude/hooks/ai-tracker.js`
3. Test manually: `~/.config/.claude/hooks/test-hook.sh`
4. Check Node.js: `node --version` (should be v14+)

### No entries in log file:
1. Check debug log: `tail ~/.local/share/nvim/ai-tracker-debug.log`
2. Verify file paths are absolute
3. Ensure Edit/Write tools are being used (not just text generation)

### Neovim not showing changes:
1. Verify log file exists: `ls ~/.local/share/nvim/ai-changes.jsonl`
2. Check entries are valid JSON: `tail -5 ~/.local/share/nvim/ai-changes.jsonl | jq .`
3. Reload Neovim or run `:AITrackerReload`

## 🎯 Success Criteria

You'll know it's working when:
1. ✅ Test script passes
2. ✅ JSONL entries appear after Claude Code changes files
3. ✅ Neovim shows orange line numbers on modified lines
4. ✅ `<C-g><C-g>` shows entries with `source: "claudecode"`
5. ✅ Debug log shows `[CLAUDE CODE]` entries

---

**Status**: ✅ Fully functional and tested
**Compatibility**: Works with existing Neovim AI tracker plugin (no changes needed)
**Maintenance**: Zero - runs automatically
