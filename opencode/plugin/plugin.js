/**
 * AI Changes Tracker - OpenCode Plugin
 * Tracks file changes made by OpenCode's Edit and Write tools
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
  const logEntry = `[${timestamp}] ${message}${data ? ': ' + JSON.stringify(data) : ''}\n`;
  try {
    appendFileSync(DEBUG_LOG_FILE, logEntry);
  } catch (err) {
    // Silent fail for debug logs
  }
}

// Track the current prompt/session context
let currentPrompt = "";
let lastUserMessageId = "";
let sessionId = `opencode-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

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
    source: "opencode",
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
 * OpenCode Plugin - Default export for main plugin
 */
export default async (context) => {
  // Handle different context structures
  const project = context?.project;
  const directory = context?.directory || process.cwd();
  
  debugLog("Plugin initialized!");
  debugLog("Context received", context ? Object.keys(context) : 'no context');
  debugLog("Working directory", directory);

  return {
    // Use the event handler which is more reliable
    event: async ({ event }) => {
      // Log ALL events to understand what's available
      const fullEventStr = JSON.stringify(event);
      debugLog("Event received", {
        type: event?.type,
        dataKeys: event?.data ? Object.keys(event.data) : 'no data',
        eventSize: fullEventStr.length,
        fullEvent: fullEventStr.length > 500 ? fullEventStr.substring(0, 500) + '...' : fullEventStr
      });
      
      // Debug only - don't log detected operations to reduce noise
      if (fullEventStr.includes('filePath') || fullEventStr.includes('file_path')) {
        debugLog("POTENTIAL FILE OPERATION DETECTED", {
          eventType: event?.type,
          searchResult: fullEventStr.substring(0, 1000)
        });
      }
      
      // Handle message events
      if (event?.type === "message" && event?.data) {
        const message = event.data;
        if (message.role === "user") {
          currentPrompt = message.content || "";
          debugLog("User prompt captured", { length: currentPrompt.length });
        }
      }
      
      // Also check message.part.updated for user prompts (this is where they actually come from)
      if (event?.type === "message.part.updated" && event?.properties?.part) {
        const part = event.properties.part;
        // Check if this is a user message by looking at the messageID pattern
        if (part.type === "text" && part.text && !part.tool) {
          // Check if this looks like a user message (no tool, has text, different message ID pattern)
          const messageId = part.messageID;
          // Store the user prompt if it's from a different message than the last one we saw
          if (messageId && messageId !== lastUserMessageId) {
            // Check if the message looks like it's from the user (heuristic: doesn't contain system prompt text)
            if (!part.text.includes("You are Claude Code") && !part.text.includes("I'll help")) {
              currentPrompt = part.text;
              lastUserMessageId = messageId;
              debugLog("User prompt captured from message.part.updated", { 
                length: currentPrompt.length,
                preview: currentPrompt.substring(0, 100),
                messageId: messageId
              });
            }
          }
        }
      }
      
      // Handle tool events
      if (event?.type === "tool" && event?.data) {
        const toolData = event.data;
        debugLog("Tool event", { tool: toolData.tool });
        
        // Only handle edit and write tools, skip others
        if (toolData.tool === "edit" && toolData.args?.filePath) {
          const { filePath, oldString, newString, replaceAll } = toolData.args;
          
          // Validate file path before logging
          if (filePath && filePath.startsWith('/') && !filePath.includes('\\')) {
            const lineNumber = findLineNumber(filePath, oldString);
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
        }
        
        if (toolData.tool === "write" && toolData.args?.filePath) {
          const { filePath, content } = toolData.args;
          
          // Validate file path before logging
          if (filePath && filePath.startsWith('/') && !filePath.includes('\\')) {
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
        }
      }
      
      // Skip storage.write events - they don't contain file operations
      // These were causing corrupted entries with malformed paths
      
      // Handle message.part.updated events which might contain tool info
      if (event?.type === "message.part.updated" && event?.properties) {
        const part = event.properties?.part;
        
        if (part?.type === 'tool' && part?.tool) {
          debugLog("TOOL EVENT FOUND IN MESSAGE PART", {
            partType: part.type,
            tool: part.tool,
            partId: part.id,
            hasState: !!part.state,
            stateStatus: part.state?.status,
            fullPart: JSON.stringify(part).substring(0, 500)
          });
          
          // Check for file path in state.input (where OpenCode puts the args)
          if (part.state?.input) {
            const input = part.state.input;
            debugLog("TOOL INPUT FOUND", { 
              tool: part.tool,
              inputKeys: Object.keys(input),
              filePath: input.filePath || input.file_path 
            });
            
            // Handle edit tool
            if (part.tool === "edit" && input.filePath) {
              // Validate file path before logging
              if (input.filePath && input.filePath.startsWith('/') && !input.filePath.includes('\\')) {
                const lineNumber = findLineNumber(input.filePath, input.oldString || '');
                debugLog('Edit tool line number calculation', { 
                  file: input.filePath,
                  lineNumber: lineNumber,
                  oldStringPreview: (input.oldString || '').substring(0, 50)
                });
                logChange({
                  tool: 'edit',
                  file_path: input.filePath,
                  line_number: lineNumber,
                  old_string: input.oldString?.substring(0, 200),
                  new_string: input.newString?.substring(0, 200),
                  replace_all: input.replaceAll || false,
                  prompt: currentPrompt.substring(0, 500),
                  event_source: 'message.part.updated'
                });
              }
            }
            
            // Handle write tool
            if (part.tool === "write" && input.filePath) {
              // Validate file path before logging
              if (input.filePath && input.filePath.startsWith('/') && !input.filePath.includes('\\')) {
                let isNewFile = true;
                try {
                  readFileSync(input.filePath);
                  isNewFile = false;
                } catch (err) {
                  // File doesn't exist, it's new
                }
                
                logChange({
                  tool: 'write',
                  file_path: input.filePath,
                  line_number: 1,
                  is_new_file: isNewFile,
                  content_length: input.content?.length || 0,
                  prompt: currentPrompt.substring(0, 500),
                  event_source: 'message.part.updated'
                });
              }
            }
          }
          
          // Removed legacy fallback handler that was creating corrupted entries
        }
      }
      
      // Handle session events
      if (event?.type === "session.idle") {
        debugLog("Session idle - completed");
      }
      
      // Handle tool_use events (alternative format)
      if (event?.type === "tool_use" && event?.data) {
        debugLog("Tool use event", event.data);
        const { name, arguments: args } = event.data;
        
        if (name === "edit" && args?.filePath) {
          const lineNumber = findLineNumber(args.filePath, args.oldString);
          logChange({
            tool: 'edit',
            file_path: args.filePath,
            line_number: lineNumber,
            old_string: args.oldString?.substring(0, 200),
            new_string: args.newString?.substring(0, 200),
            replace_all: args.replaceAll || false,
            prompt: currentPrompt.substring(0, 500),
          });
        }
        
        if (name === "write" && args?.filePath) {
          logChange({
            tool: 'write', 
            file_path: args.filePath,
            line_number: 1,
            is_new_file: true,
            content_length: args.content?.length || 0,
            prompt: currentPrompt.substring(0, 500),
          });
        }
      }
    }
  };
};