#!/bin/bash
# Test script for Claude Code AI Tracker Hook

echo "Testing Claude Code AI Tracker Hook..."
echo ""

# Create test input that mimics Claude Code's PostToolUse hook data
TEST_INPUT='{
  "session_id": "test-session-123",
  "transcript_path": "/tmp/test-transcript.jsonl",
  "cwd": "'$PWD'",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "'$HOME'/.config/.claude/hooks/test-file.txt",
    "old_string": "old content",
    "new_string": "new content",
    "replace_all": false
  },
  "tool_response": {
    "success": true
  }
}'

# Create a test transcript file
mkdir -p /tmp
echo '{"role":"user","content":[{"type":"text","text":"Test prompt for AI tracker"}]}' > /tmp/test-transcript.jsonl

# Create test file
echo "old content" > ~/.config/.claude/hooks/test-file.txt

echo "Test input:"
echo "$TEST_INPUT" | jq .
echo ""

echo "Running hook..."
echo "$TEST_INPUT" | node ~/.config/.claude/hooks/ai-tracker.js

echo ""
echo "Hook execution complete!"
echo ""

# Check if log was created
if [ -f ~/.local/share/nvim/ai-changes.jsonl ]; then
  echo "✅ Log file created successfully!"
  echo ""
  echo "Last entry:"
  tail -1 ~/.local/share/nvim/ai-changes.jsonl | jq .
else
  echo "❌ Log file not created"
fi

echo ""

# Check debug log
if [ -f ~/.local/share/nvim/ai-tracker-debug.log ]; then
  echo "Debug log (last 5 lines):"
  tail -5 ~/.local/share/nvim/ai-tracker-debug.log
else
  echo "No debug log created"
fi

# Cleanup
rm -f ~/.config/.claude/hooks/test-file.txt
rm -f /tmp/test-transcript.jsonl
