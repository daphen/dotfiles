#!/usr/bin/env bash

# Start Focus toggle in background immediately
shortcuts run "Toggle Focus" &

# Get current state and toggle icon (don't wait for system to update)
if [ "$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes")" = "1" ]; then
    # Currently on, turning off - add small delay before UI update
    sketchybar --set dnd icon="" icon.color=0xffffffff
else
    # If currently off, we're turning it on
    sketchybar --set dnd icon="󰽧" icon.color=0xffffffff
fi
