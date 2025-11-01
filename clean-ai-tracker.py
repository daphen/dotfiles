#!/usr/bin/env python3
"""Clean up corrupted AI tracker entries."""

import json
import os
import sys
from pathlib import Path

def is_valid_file_path(path):
    """Check if the path is a valid file path without escape sequences."""
    if not path:
        return False
    
    # Check for common escape sequences and malformed paths
    if any(seq in path for seq in ['\\n', '\\t', '\\r', '\\\\']):
        return False
    
    # Check for paths ending with :number (line numbers appended)
    if path.endswith(':1') or path.endswith('\\'):
        return False
    
    # Should start with / (absolute path)
    if not path.startswith('/'):
        return False
    
    # Should not contain these patterns
    invalid_patterns = [
        'file not found:',
        'error:',
        '/.config\\n',
        '/.config\n',
    ]
    
    for pattern in invalid_patterns:
        if pattern in path.lower():
            return False
    
    return True

def clean_ai_changes_log():
    """Clean the AI changes log file."""
    log_file = os.path.expanduser('~/.local/share/nvim/ai-changes.jsonl')
    
    if not os.path.exists(log_file):
        print(f"Log file not found: {log_file}")
        return
    
    # Read all entries
    entries = []
    corrupted_count = 0
    
    with open(log_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            if not line.strip():
                continue
            
            try:
                entry = json.loads(line)
                
                # Check if file_path is valid
                file_path = entry.get('file_path', '')
                
                if not is_valid_file_path(file_path):
                    print(f"Line {line_num}: Removing corrupted entry with path: {repr(file_path)}")
                    corrupted_count += 1
                    continue
                
                # Also skip entries with "detected" tool (these are debug entries)
                if entry.get('tool') == 'detected':
                    print(f"Line {line_num}: Removing debug entry")
                    corrupted_count += 1
                    continue
                    
                entries.append(entry)
                
            except json.JSONDecodeError as e:
                print(f"Line {line_num}: Failed to parse JSON: {e}")
                corrupted_count += 1
                continue
    
    # Backup original file
    backup_file = log_file + '.backup'
    os.rename(log_file, backup_file)
    print(f"Created backup: {backup_file}")
    
    # Write cleaned entries
    with open(log_file, 'w') as f:
        for entry in entries:
            f.write(json.dumps(entry) + '\n')
    
    print(f"\nCleaning complete!")
    print(f"- Removed {corrupted_count} corrupted entries")
    print(f"- Kept {len(entries)} valid entries")
    print(f"- Original file backed up to: {backup_file}")

if __name__ == '__main__':
    clean_ai_changes_log()