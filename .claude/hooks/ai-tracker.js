#!/usr/bin/env node
/**
 * AI Changes Tracker - Claude Code Hook
 * Tracks file changes made by Claude Code's Edit and Write tools
 * Functionally identical to the OpenCode plugin
 */

import { appendFileSync, readFileSync, mkdirSync } from 'fs';
import { homedir } from 'os';
import { join, dirname } from 'path';

const LOG_FILE = join(homedir(), '.local/share/nvim/ai-changes.jsonl');
const DEBUG_LOG_FILE = join(homedir(), '.local/share/nvim/ai-tracker-debug.log');

// Ensure log directory exists
const logDir = dirname(LOG_FILE);
try {
  mkdirSync(logDir, { recursive: true });
} catch (err) {
  // Directory might already exist
}

// Debug logging function
function debugLog(message, data = null) {
  const timestamp = new Date().toISOString();
  const logEntry = `[${timestamp}] [CLAUDE CODE] ${message}${data ? ': ' + JSON.stringify(data) : ''}\n`;
  try {
    appendFileSync(DEBUG_LOG_FILE, logEntry);
  } catch (err) {
    // Silent fail for debug logs
  }
}

// Track the current prompt/session context
let currentPrompt = "";
let sessionId = `claudecode-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

// Track recently logged changes to prevent duplicates
const recentChanges = new Map(); // key: hash of change, value: timestamp
const DUPLICATE_WINDOW_MS = 1000; // Consider duplicates within 1 second

/**
 * Find line number where a string appears in a file
 */
function findLineNumber(filePath, searchString) {
  try {
    const content = readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    const searchLines = searchString.split('\n');
    const firstSearchLine = searchLines[0];

    // Try to find exact match of the first line
    for (let i = 0; i < lines.length; i++) {
      // Check for exact match or if the line contains the search string
      if (lines[i] === firstSearchLine || (firstSearchLine && lines[i].includes(firstSearchLine))) {
        // Verify it's actually the right location by checking multiple lines if possible
        if (searchLines.length > 1 && i + 1 < lines.length) {
          // Check if next line also matches
          if (lines[i + 1].includes(searchLines[1] || '')) {
            debugLog('Found exact line match', { line: i + 1, content: firstSearchLine.substring(0, 50) });
            return i + 1; // 1-based line number
          }
        } else {
          debugLog('Found line match', { line: i + 1, content: firstSearchLine.substring(0, 50) });
          return i + 1; // 1-based line number
        }
      }
    }

    debugLog('No line match found, defaulting to line 1', { searchString: firstSearchLine.substring(0, 50) });
    return 1;
  } catch (err) {
    debugLog('Could not read file for line number', { error: err.message });
    return 1;
  }
}

/**
 * Create a hash key for deduplication
 */
function createChangeKey(entry) {
  return `${entry.tool}|${entry.file_path}|${entry.line_number}|${entry.old_string?.substring(0, 50)}|${entry.new_string?.substring(0, 50)}`;
}

/**
 * Log a change entry to the JSONL file (with deduplication)
 */
function logChange(entry) {
  // Create a key for this change
  const changeKey = createChangeKey(entry);
  const now = Date.now();

  // Check if we've seen this change recently
  const lastSeen = recentChanges.get(changeKey);
  if (lastSeen && (now - lastSeen) < DUPLICATE_WINDOW_MS) {
    debugLog('Skipping duplicate change', {
      file: entry.file_path,
      timeSinceLastSeen: now - lastSeen
    });
    return;
  }

  // Update the seen timestamp
  recentChanges.set(changeKey, now);

  // Clean up old entries periodically (keep map from growing too large)
  if (recentChanges.size > 100) {
    for (const [key, timestamp] of recentChanges.entries()) {
      if (now - timestamp > DUPLICATE_WINDOW_MS * 10) {
        recentChanges.delete(key);
      }
    }
  }

  const jsonLine = JSON.stringify({
    timestamp: new Date().toISOString(),
    session_id: sessionId,
    source: "claudecode",
    ...entry
  }) + '\n';

  try {
    appendFileSync(LOG_FILE, jsonLine);
    debugLog(`Logged change to ${entry.file_path}`);
  } catch (err) {
    debugLog('Failed to log change', { error: err.message });
  }
}

/**
 * Extract user prompt from transcript file
 */
function extractPromptFromTranscript(transcriptPath) {
  try {
    const content = readFileSync(transcriptPath, 'utf8');
    const lines = content.trim().split('\n');

    // Parse JSONL and find the most recent user message
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const entry = JSON.parse(lines[i]);
        if (entry.role === 'user' && entry.content) {
          // Extract text from content array
          if (Array.isArray(entry.content)) {
            const textContent = entry.content.find(c => c.type === 'text');
            if (textContent && textContent.text) {
              debugLog('Extracted prompt from transcript', {
                length: textContent.text.length,
                preview: textContent.text.substring(0, 100)
              });
              return textContent.text;
            }
          } else if (typeof entry.content === 'string') {
            debugLog('Extracted prompt from transcript (string)', {
              length: entry.content.length,
              preview: entry.content.substring(0, 100)
            });
            return entry.content;
          }
        }
      } catch (parseErr) {
        // Skip invalid JSON lines
      }
    }
  } catch (err) {
    debugLog('Could not read transcript', { error: err.message });
  }
  return "Unknown prompt";
}

/**
 * Main hook handler
 */
function handlePostToolUse() {
  debugLog("Hook triggered!");

  // Read JSON from stdin
  let inputData = '';

  process.stdin.on('data', chunk => {
    inputData += chunk;
  });

  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(inputData);

      debugLog("Received hook data", {
        tool: data.tool_name,
        cwd: data.cwd,
        hasInput: !!data.tool_input,
        hasResponse: !!data.tool_response
      });

      // Extract user prompt from transcript
      if (data.transcript_path) {
        currentPrompt = extractPromptFromTranscript(data.transcript_path);
      }

      const toolName = data.tool_name?.toLowerCase(); // "edit" or "write"
      const toolInput = data.tool_input || {};

      // Normalize field names (Claude Code uses different names than OpenCode)
      const filePath = toolInput.file_path || toolInput.filePath;
      const oldString = toolInput.old_string || toolInput.oldString;
      const newString = toolInput.new_string || toolInput.newString;
      const replaceAll = toolInput.replace_all || toolInput.replaceAll;
      const content = toolInput.content;

      // Validate file path before logging
      if (!filePath || !filePath.startsWith('/') || filePath.includes('\\')) {
        debugLog('Invalid file path, skipping', { filePath });
        process.exit(0);
        return;
      }

      // Handle edit tool
      if (toolName === 'edit') {
        const lineNumber = findLineNumber(filePath, newString || oldString || '');
        logChange({
          tool: 'edit',
          file_path: filePath,
          line_number: lineNumber,
          old_string: oldString?.substring(0, 200),
          new_string: newString?.substring(0, 200),
          replace_all: replaceAll || false,
          prompt: currentPrompt.substring(0, 500),
        });
      }

      // Handle write tool
      if (toolName === 'write') {
        let isNewFile = true;
        try {
          readFileSync(filePath);
          isNewFile = false;
        } catch (err) {
          // File doesn't exist, it's new
        }

        logChange({
          tool: 'write',
          file_path: filePath,
          line_number: 1,
          is_new_file: isNewFile,
          content_length: content?.length || 0,
          prompt: currentPrompt.substring(0, 500),
        });
      }

      debugLog('Hook completed successfully');

    } catch (err) {
      debugLog('Error processing hook data', { error: err.message, stack: err.stack });
    }

    // Exit successfully (no output to user)
    process.exit(0);
  });
}

// Run the hook handler
handlePostToolUse();
