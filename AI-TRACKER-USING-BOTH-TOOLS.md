# Using OpenCode and Claude Code Together

## ✅ Yes, You Can Use Both Tools Interchangeably!

Your AI tracker is designed to handle **both OpenCode and Claude Code simultaneously** with zero conflicts.

## 📊 Current State

Your log file already has entries from both:

```bash
$ cat ~/.local/share/nvim/ai-changes.jsonl | jq -r '.source' | sort | uniq -c
   1 claudecode  ← Claude Code entries
  52 opencode    ← OpenCode entries
```

## 🔄 How It Works

Both tools write to the **same JSONL file** using append mode:

```
~/.local/share/nvim/ai-changes.jsonl
├── opencode entry   (10:00 AM)
├── opencode entry   (10:15 AM)
├── claudecode entry (11:00 AM)  ← Switch to Claude Code
├── claudecode entry (11:30 AM)
├── opencode entry   (12:00 PM)  ← Switch back to OpenCode
└── claudecode entry (12:30 PM)  ← Switch back to Claude Code
```

### Why This Works

1. **Append-only writes** - No overwrites, no conflicts
2. **Unique session IDs** - Each session is tracked separately
3. **Source field** - Entries are tagged with their origin
4. **Chronological ordering** - Entries appear in the order they were made

## 🎮 Neovim Behavior

Your Neovim plugin **automatically shows both** without any configuration:

### Default View (`<C-g><C-g>`)
Shows **all changes** from both sources, sorted by timestamp:

```
[2 hours ago] (15) hooks/ai-tracker.js:1              ← Claude Code
[3 hours ago] (8)  highlight-context-menu.tsx:45     ← OpenCode
[4 hours ago] (3)  auth.ts:123                        ← OpenCode
[5 hours ago] (2)  config.lua:67                      ← Claude Code
```

The picker **doesn't distinguish** between sources by default - they're all just "AI changes".

### Session View (`<C-g>s`)
Shows sessions **separately**:

```
[2 hours ago] ClaudeCode 10/27 21:17 - 1 changes in 1 file
[3 hours ago] OpenCode 10/27 18:38 - 8 changes in 1 file
```

Each AI tool session is tracked independently!

### Grouped by Prompt (`<C-g>p`)
Groups changes **regardless of source**:

```
[2 hours ago] Add AI tracker hook (1 file)           ← Claude Code
[3 hours ago] Fix context menu bug (1 file)          ← OpenCode
```

## 💡 Practical Workflows

### Workflow 1: Feature Development
```bash
# Start with Claude Code
claudecode
> "Create a new authentication module"
  → Writes auth.ts, auth.test.ts

# Switch to OpenCode for refinement
opencode
> "Add error handling to auth module"
  → Edits auth.ts

# Back to Claude Code for documentation
claudecode
> "Add JSDoc comments to auth functions"
  → Edits auth.ts

# View all changes in Neovim
nvim auth.ts
<C-g>f  # See all changes from BOTH tools chronologically
```

### Workflow 2: Project-Wide Changes
```bash
# Use Claude Code for config changes
claudecode
> "Update TypeScript config for strict mode"
  → Edits tsconfig.json, 5 source files

# Use OpenCode for testing
opencode
> "Add tests for the updated components"
  → Writes 3 test files

# View in Neovim
nvim
<C-g><C-g>  # See all changes from both sessions
```

### Workflow 3: Session-Based Review
```bash
# Morning: OpenCode session
opencode
> "Refactor user service"

# Afternoon: Claude Code session
claudecode
> "Add API endpoints"

# Review in Neovim
nvim
<C-g>s  # Shows TWO separate sessions
        # You can see what each tool did independently
```

## 🎯 Common Scenarios

### Scenario 1: Both Tools Edit Same File
```
File: auth.ts

10:00 AM - OpenCode   - Line 45: Add async/await
10:30 AM - Claude Code - Line 67: Add error handling
11:00 AM - OpenCode   - Line 45: Refine async logic
```

**Result in Neovim:**
- Lines 45 and 67 both show orange line numbers
- `<C-g>f` shows all 3 changes chronologically
- `<C-g>j`/`<C-g>k` navigates between all changes

### Scenario 2: Each Tool Works on Different Files
```
OpenCode:   auth.ts, user.ts
Claude Code: config.lua, setup.sh
```

**Result in Neovim:**
- `<C-g><C-g>` shows all 4 files
- Each file's changes are attributed correctly
- Sessions are separate: 2 OpenCode sessions, 2 Claude Code sessions

### Scenario 3: Rapid Switching
```
10:00 - OpenCode:   Edit file A
10:05 - Claude Code: Edit file B
10:10 - OpenCode:   Edit file A again
10:15 - Claude Code: Edit file B again
```

**Result:**
- All 4 changes logged chronologically
- No conflicts, no lost data
- Each tool's session ID remains consistent within its session

## 🔍 Filtering by Source (If Needed)

If you want to see **only** OpenCode or **only** Claude Code changes:

### Command Line
```bash
# Only OpenCode changes
cat ~/.local/share/nvim/ai-changes.jsonl | jq 'select(.source == "opencode")'

# Only Claude Code changes
cat ~/.local/share/nvim/ai-changes.jsonl | jq 'select(.source == "claudecode")'
```

### In Neovim (Custom Command)
You could add a custom filter to your AI tracker plugin if needed:

```lua
-- Show only OpenCode changes
vim.api.nvim_create_user_command("AITrackerOpenCode", function()
  local changes = require("ai-tracker").get_changes()
  local filtered = vim.tbl_filter(function(c)
    return c.source == "opencode"
  end, changes)
  require("ai-tracker.picker").show(filtered, { title = "OpenCode Changes" })
end, {})

-- Show only Claude Code changes
vim.api.nvim_create_user_command("AITrackerClaudeCode", function()
  local changes = require("ai-tracker").get_changes()
  local filtered = vim.tbl_filter(function(c)
    return c.source == "claudecode"
  end, changes)
  require("ai-tracker.picker").show(filtered, { title = "Claude Code Changes" })
end, {})
```

But **by default, you probably want to see all changes** regardless of source!

## 📈 Benefits of Using Both

### 1. **Flexibility**
- Use the right tool for the job
- Switch mid-project without losing tracking
- Compare how each tool approaches problems

### 2. **Comprehensive History**
- Single source of truth for all AI changes
- Complete audit trail across tools
- Easy to see the evolution of your codebase

### 3. **Session-Based Analysis**
- Compare OpenCode vs Claude Code sessions
- See which tool made which changes
- Understand different AI approaches

### 4. **No Maintenance**
- Both hooks run automatically
- No manual switching or configuration
- Just use whichever tool you want!

## ⚠️ Things to Know

### Session IDs Are Different
```json
{"session_id": "opencode-1234-abc123"}    // OpenCode
{"session_id": "claudecode-5678-def456"}  // Claude Code
```

This means:
- ✅ Sessions are tracked separately
- ✅ No confusion between which tool made which changes
- ✅ Session view shows them as distinct sessions

### Timestamps Are Precise
Both use ISO 8601 format with milliseconds:
```json
{"timestamp": "2025-10-27T20:17:00.429Z"}
```

This means:
- ✅ Changes are ordered precisely
- ✅ Even rapid switches are captured correctly
- ✅ You can see the exact chronology

### Line Numbers Can Shift
If both tools edit the same file:
```
10:00 - OpenCode adds 10 lines at top of file
10:30 - Claude Code edits line 50 (now actually line 60)
```

The tracker stores the **line number at time of change**, so:
- ✅ Historical accuracy is maintained
- ⚠️  Current line numbers may differ if file was edited between changes

## 🎯 Recommendation

**Use both tools freely!** The system is designed for this:

1. **No conflicts** - Both can write simultaneously
2. **No data loss** - Append-only operations are atomic
3. **Complete history** - Every change is captured
4. **Easy navigation** - Neovim shows all changes seamlessly

You don't need to think about which tool you're using - just focus on getting work done, and your AI tracker will handle the rest!

## 📝 Example: Full Day's Work

```
Morning (OpenCode):
09:00 - "Set up new React component"
       → Creates Button.tsx, Button.test.tsx, Button.stories.tsx

Midday (Claude Code):
12:00 - "Add TypeScript strict mode to project"
       → Edits tsconfig.json, fixes 15 files

Afternoon (OpenCode):
15:00 - "Add dark mode support to Button"
       → Edits Button.tsx, adds CSS

Evening (Claude Code):
18:00 - "Write documentation for Button component"
       → Creates Button.md, adds JSDoc

End of day in Neovim:
<C-g><C-g>  → See all 20 file changes from both tools
<C-g>s      → See 2 OpenCode sessions + 2 Claude Code sessions
<C-g>p      → See 4 prompts grouped by task
```

**Result**: Complete picture of your day's work, regardless of which tool you used!

---

## Summary

✅ **YES - Use both tools interchangeably**
✅ **NO conflicts** - Safe concurrent writes
✅ **NO changes needed** - Works out of the box
✅ **NO thinking required** - Just use whichever tool you want!

The AI tracker was designed to be **tool-agnostic** from the start. Now you have the best of both worlds! 🎉
