#!/usr/bin/env bash

# Get target output from argument (e.g., "DP-1", "eDP-1", or "external" for auto-detect)
target_output="${1:-}"

# Auto-detect external monitor if "external" is passed
if [[ "$target_output" == "external" ]]; then
    target_output=$(niri msg outputs 2>/dev/null | grep -oP '\(DP-[0-9]+\)' | head -1 | tr -d '()')
    [[ -z "$target_output" ]] && { echo '[{"active":true}]'; exit 0; }
fi

# Get workspace and window data in JSON
workspaces_json=$(niri msg -j workspaces 2>/dev/null)
windows=$(niri msg windows 2>/dev/null)

# Find the active workspace ID for the target output
if [ -n "$target_output" ]; then
    # Get the active workspace for this specific output
    target_workspace=$(echo "$workspaces_json" | jq -r ".[] | select(.output == \"$target_output\" and .is_active == true) | .id")
    # Get the active window ID for this workspace to determine the focused column
    active_window_id=$(echo "$workspaces_json" | jq -r ".[] | select(.output == \"$target_output\" and .is_active == true) | .active_window_id")
else
    # Fallback: use the globally focused workspace
    focused=$(niri msg focused-window 2>/dev/null)
    target_workspace=$(echo "$focused" | grep "Workspace ID:" | awk '{print $3}')
    active_window_id=""
fi

if [ -z "$target_workspace" ]; then
    echo '[{"active":true}]'
    exit 0
fi

# Get the focused column for this workspace's active window
if [ -n "$active_window_id" ] && [ "$active_window_id" != "null" ]; then
    focused_column=$(echo "$windows" | grep -A 20 "Window ID $active_window_id:" | grep "Scrolling position:" | sed 's/.*column \([0-9]*\).*/\1/' | head -1)
else
    focused_column=""
fi

# Parse all windows on target workspace and get their columns
declare -A columns
current_ws=""
while IFS= read -r line; do
    if [[ $line =~ "Window ID" ]]; then
        current_ws=""
    elif [[ $line =~ "Workspace ID: $target_workspace" ]]; then
        current_ws="$target_workspace"
    elif [[ -n "$current_ws" ]] && [[ $line =~ "Scrolling position: column "([0-9]+) ]]; then
        col="${BASH_REMATCH[1]}"
        columns[$col]=1
    fi
done <<< "$windows"

# If only one column or no columns, show single indicator
if [ ${#columns[@]} -le 1 ]; then
    echo '[{"active":true}]'
    exit 0
fi

# Build JSON array - sort columns and mark current position
sorted_cols=($(for col in "${!columns[@]}"; do echo "$col"; done | sort -n))

json="["
first=true
for col in "${sorted_cols[@]}"; do
    if [ "$first" = true ]; then
        first=false
    else
        json="${json},"
    fi

    if [ -n "$focused_column" ] && [ "$col" -eq "$focused_column" ]; then
        json="${json}{\"active\":true}"
    else
        json="${json}{\"active\":false}"
    fi
done
json="${json}]"

echo "$json"
