#!/usr/bin/env bash

# Get target output from argument (e.g., "DP-1", "eDP-1", or "external" for auto-detect)
target_output="${1:-}"

# Auto-detect external monitor if "external" is passed
if [[ "$target_output" == "external" ]]; then
    target_output=$(niri msg outputs 2>/dev/null | grep -oP '\(DP-[0-9]+\)' | head -1 | tr -d '()')
    [[ -z "$target_output" ]] && { echo '[]'; exit 0; }
fi

# Get all workspaces
workspaces=$(niri msg workspaces 2>/dev/null)

# Build JSON array of workspace states for the target output
json="["
first=true
current_output=""
in_target_output=false

while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Check if this is an output header line
    if [[ "$line" =~ ^Output\ \"(.*)\":$ ]]; then
        current_output="${BASH_REMATCH[1]}"
        # If no target specified, match all; otherwise check if we're in the target output
        if [[ -z "$target_output" ]] || [[ "$current_output" == "$target_output" ]]; then
            in_target_output=true
        else
            in_target_output=false
        fi
        continue
    fi

    # Skip if we're not in the target output
    [[ "$in_target_output" != true ]] && continue

    # Check if this is the active workspace (has *)
    if [[ "$line" =~ \* ]]; then
        active="true"
    else
        # Extract workspace number (skip if not a number line)
        ws=$(echo "$line" | tr -d ' ')
        if [[ ! "$ws" =~ ^[0-9]+$ ]]; then
            continue
        fi
        active="false"
    fi

    if [ "$first" = true ]; then
        first=false
    else
        json="${json},"
    fi
    json="${json}{\"active\":${active}}"
done <<< "$workspaces"

json="${json}]"
echo "$json"
