#!/usr/bin/env bash

# Output current state first
get_workspaces() {
    workspaces=$(niri msg workspaces 2>/dev/null)
    json="["
    first=true
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^Output ]] && continue
        if [[ "$line" =~ \* ]]; then
            active="true"
        else
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
}

# Initial output
get_workspaces

# Listen for workspace changes
niri msg event-stream 2>/dev/null | while read -r line; do
    if [[ "$line" =~ "Workspaces changed" ]] || [[ "$line" =~ "is_focused: true" ]]; then
        get_workspaces
    fi
done
