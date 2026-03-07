#!/usr/bin/env bash
# Live Test for AI Tracker Hook
# This simulates what Claude Code does when you make changes

set -e

echo "🧪 AI Tracker Live Test"
echo "======================="
echo ""

# Get current count
BEFORE_COUNT=$(wc -l < ~/.local/share/nvim/ai-changes.jsonl 2>/dev/null || echo "0")
echo "📊 Current log entries: $BEFORE_COUNT"
echo ""

# Create a test file in /tmp
TEST_FILE="/tmp/ai-tracker-live-test-$(date +%s).txt"
echo "Creating test file: $TEST_FILE"
echo "Original content" > "$TEST_FILE"

# Create a mock transcript (simulates your actual prompt)
TRANSCRIPT_FILE="/tmp/test-transcript-$(date +%s).jsonl"
cat > "$TRANSCRIPT_FILE" << 'EOF'
{"role":"user","content":[{"type":"text","text":"Fix the authentication bug in the login component"}]}
EOF

# Create hook input that mimics Claude Code
HOOK_INPUT=$(cat <<EOF
{
  "session_id": "test-session-$(date +%s)",
  "transcript_path": "$TRANSCRIPT_FILE",
  "cwd": "$(pwd)",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "$TEST_FILE",
    "old_string": "Original content",
    "new_string": "Fixed content with authentication",
    "replace_all": false
  },
  "tool_response": {
    "success": true
  }
}
EOF
)

echo ""
echo "🚀 Triggering hook with Edit operation..."
echo ""

# Run the hook
echo "$HOOK_INPUT" | node ~/.claude/hooks/ai-tracker.js

# Wait a moment for file write
sleep 1

# Check results
AFTER_COUNT=$(wc -l < ~/.local/share/nvim/ai-changes.jsonl 2>/dev/null || echo "0")

echo ""
echo "📊 Results:"
echo "==========="
echo "Entries before: $BEFORE_COUNT"
echo "Entries after:  $AFTER_COUNT"

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
  echo ""
  echo "✅ SUCCESS! Hook is working!"
  echo ""
  echo "📝 Latest entry:"
  tail -1 ~/.local/share/nvim/ai-changes.jsonl | jq .
  echo ""
  echo "🎯 Next steps:"
  echo "   1. Open Neovim"
  echo "   2. Press <C-g><C-g> to see the change"
  echo "   3. Try making changes in a NEW Claude Code conversation"
else
  echo ""
  echo "❌ FAILED! Hook did not log the change"
  echo ""
  echo "🔍 Debug log (last 10 lines):"
  tail -10 ~/.local/share/nvim/ai-tracker-debug.log 2>/dev/null || echo "No debug log found"
fi

echo ""
echo "🧹 Cleanup..."
rm -f "$TEST_FILE" "$TRANSCRIPT_FILE"

echo "Done!"
