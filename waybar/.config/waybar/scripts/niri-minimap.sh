#!/bin/bash

# Get focused window and all windows info
focused=$(niri msg focused-window 2>/dev/null)
windows=$(niri msg windows 2>/dev/null)

# Extract focused window's workspace and column
focused_workspace=$(echo "$focused" | grep "Workspace ID:" | awk '{print $3}')
focused_column=$(echo "$focused" | grep "Scrolling position:" | sed 's/.*column \([0-9]*\).*/\1/')

if [ -z "$focused_workspace" ] || [ -z "$focused_column" ]; then
    echo '{"text": "◆", "tooltip": "No active window"}'
    exit 0
fi

# Parse all windows on current workspace and get their columns
declare -A columns
while IFS= read -r line; do
    if [[ $line =~ "Window ID" ]]; then
        current_window="$line"
        in_focused_workspace=0
    elif [[ $line =~ "Workspace ID: $focused_workspace" ]]; then
        in_focused_workspace=1
    elif [[ $in_focused_workspace -eq 1 ]] && [[ $line =~ "Scrolling position: column "([0-9]+) ]]; then
        col="${BASH_REMATCH[1]}"
        columns[$col]=1
    fi
done <<< "$windows"

# If only one column, show single indicator
if [ ${#columns[@]} -le 1 ]; then
    echo '{"text": "◆", "tooltip": "Single column"}'
    exit 0
fi

# Build minimap - sort columns and show current position
minimap=""
sorted_cols=($(for col in "${!columns[@]}"; do echo "$col"; done | sort -n))

for col in "${sorted_cols[@]}"; do
    if [ "$col" -eq "$focused_column" ]; then
        minimap="${minimap}◆"
    else
        minimap="${minimap}◇"
    fi
done

# Build tooltip
tooltip="WS $focused_workspace - Col $focused_column/${sorted_cols[-1]}"

echo "{\"text\": \"$minimap\", \"tooltip\": \"$tooltip\"}"
