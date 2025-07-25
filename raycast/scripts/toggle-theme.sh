#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Theme
# @raycast.mode compact
# @raycast.description Toggle macOS theme and sync all development tools
# @raycast.icon 🎨
# @raycast.packageName Theme

# Simply call the working toggle_theme function from Fish
if command -v fish >/dev/null 2>&1; then
    fish -c "toggle_theme"
else
    echo "Fish shell not found"
    exit 1
fi