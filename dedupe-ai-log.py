#!/usr/bin/env python3
"""
Deduplicate AI changes log file by removing exact duplicates
based on file_path, line_number, tool, and timestamp (within 1 second)
"""

import json
import sys
from pathlib import Path
from datetime import datetime

def parse_timestamp(ts_str):
    """Parse ISO timestamp string to datetime"""
    return datetime.fromisoformat(ts_str.replace('Z', '+00:00'))

def dedupe_log(input_file, output_file):
    seen = set()
    unique_entries = []
    duplicate_count = 0
    
    with open(input_file, 'r') as f:
        for line in f:
            if not line.strip():
                continue
                
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                print(f"Skipping invalid JSON line: {line[:50]}...")
                continue
            
            # Create a key for deduplication
            # Include file_path, line_number, tool, and timestamp (rounded to second)
            timestamp = parse_timestamp(entry.get('timestamp', ''))
            timestamp_second = timestamp.replace(microsecond=0)
            
            key = (
                entry.get('file_path', ''),
                entry.get('line_number', 0),
                entry.get('tool', ''),
                timestamp_second.isoformat(),
                entry.get('old_string', '')[:50],  # First 50 chars of old_string
                entry.get('new_string', '')[:50],  # First 50 chars of new_string
            )
            
            if key not in seen:
                seen.add(key)
                unique_entries.append(entry)
            else:
                duplicate_count += 1
    
    # Sort by timestamp (newest first)
    unique_entries.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    
    # Write deduplicated entries
    with open(output_file, 'w') as f:
        for entry in unique_entries:
            f.write(json.dumps(entry) + '\n')
    
    print(f"Deduplication complete:")
    print(f"  Original entries: {len(unique_entries) + duplicate_count}")
    print(f"  Duplicates removed: {duplicate_count}")
    print(f"  Unique entries: {len(unique_entries)}")
    print(f"  Output file: {output_file}")

if __name__ == "__main__":
    log_dir = Path.home() / '.local' / 'share' / 'nvim'
    input_file = log_dir / 'ai-changes.jsonl'
    backup_file = log_dir / 'ai-changes.jsonl.backup'
    
    # Create backup
    if input_file.exists():
        print(f"Creating backup: {backup_file}")
        backup_file.write_bytes(input_file.read_bytes())
        
        # Deduplicate
        dedupe_log(input_file, input_file)
    else:
        print(f"Log file not found: {input_file}")
        sys.exit(1)