#!/usr/bin/env bash

# Get list of audio output devices (sinks)
sinks=$(pactl list sinks short | awk '{print $2}')

# Get current default sink
current=$(pactl get-default-sink)

# Build a formatted list with friendly names - active device first
active_device=""
other_devices=""

while IFS= read -r sink; do
    # Get description (friendly name) for this sink
    description=$(pactl list sinks | grep -A 20 "Name: $sink" | grep "Description:" | cut -d: -f2- | sed 's/^[[:space:]]*//')

    if [ "$sink" = "$current" ]; then
        active_device="● $description\n"
    else
        other_devices+="  $description\n"
    fi
done <<< "$sinks"

# Put active device first
sink_list="${active_device}${other_devices}"

# Show menu and get selection
selected=$(echo -e "$sink_list" | rofi -dmenu -p "Audio Output")

if [ -n "$selected" ]; then
    # Remove the bullet point if present
    selected_clean=$(echo "$selected" | sed 's/^● //' | sed 's/^  //')

    # Find the sink name that matches this description
    while IFS= read -r sink; do
        description=$(pactl list sinks | grep -A 20 "Name: $sink" | grep "Description:" | cut -d: -f2- | sed 's/^[[:space:]]*//')
        if [ "$description" = "$selected_clean" ]; then
            pactl set-default-sink "$sink"
            # Move all currently playing streams to the new sink
            pactl list short sink-inputs | awk '{print $1}' | while read -r stream; do
                pactl move-sink-input "$stream" "$sink" 2>/dev/null
            done
            break
        fi
    done <<< "$sinks"
fi
