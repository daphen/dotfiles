#!/usr/bin/env bash
# Hook to handle image pasting from Wayland clipboard for Claude Code
# This script extracts images from wl-clipboard and saves them to a temp file
# that Claude Code can then read and encode properly

# Check if there's an image in the clipboard
if wl-paste --list-types | grep -q "image/png"; then
    # Create a temporary file
    TEMP_FILE=$(mktemp --suffix=.png)

    # Extract the image from clipboard to the temp file
    wl-paste --type image/png > "$TEMP_FILE"

    # Check if the file is not empty
    if [ -s "$TEMP_FILE" ]; then
        # Output the path for Claude Code to use
        echo "$TEMP_FILE"
    else
        # Clean up empty file
        rm "$TEMP_FILE"
        exit 1
    fi
else
    exit 1
fi
