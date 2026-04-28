#!/usr/bin/env bash
# Waybar center-module:
# - On the "lovable" workspace: emit class "lovable" + the worktree name
#   currently running in the active stack's devenv wt (CSS shows the
#   lovable logo as a background image).
# - Elsewhere: the original column-position minimap.

set -euo pipefail

focused_json=$(niri msg --json focused-window 2>/dev/null || echo "null")
focused_ws_id=$(echo "$focused_json" | jq -r '.workspace_id // empty')
focused_id=$(echo "$focused_json" | jq -r '.id // empty')
focused_col=$(echo "$focused_json" | jq -r '.layout.pos_in_scrolling_layout[0] // empty')

if [ -z "$focused_ws_id" ]; then
    echo '{"text": "", "tooltip": "No active window"}'
    exit 0
fi

workspaces_json=$(niri msg --json workspaces 2>/dev/null || echo "[]")
focused_ws_name=$(echo "$workspaces_json" \
    | jq -r --argjson id "$focused_ws_id" '.[] | select(.id == $id) | .name // ""')

# ── Lovable workspace branch ─────────────────────────────────────────────
if [ "$focused_ws_name" = "lovable" ]; then
    windows_json=$(niri msg --json windows 2>/dev/null || echo "[]")

    # Active stack name = whichever lovable_term_<x>/lovable_claude_<x> has
    # the most-recent focus_timestamp on the lovable workspace.
    active_name=$(echo "$windows_json" | jq -r --argjson ws "$focused_ws_id" '
        [ .[]
          | select(.workspace_id == $ws)
          | select((.app_id // "") | test("^lovable_(term|claude)_.+"))
          | select(.focus_timestamp != null)
        ]
        | sort_by(.focus_timestamp.secs, .focus_timestamp.nanos)
        | reverse
        | .[0].app_id // ""
        | sub("^lovable_(term|claude)_"; "")
    ')

    running=""
    if [ -n "$active_name" ]; then
        # Extract the worktree currently running in that stack's term column,
        # from the process-compose title set by `devenv wt`.
        running=$(echo "$windows_json" | jq -r --argjson ws "$focused_ws_id" --arg name "$active_name" '
            [ .[]
              | select(.workspace_id == $ws and .app_id == ("lovable_term_" + $name))
            ]
            | .[0].title // ""
            | capture("^process-compose: proart/lovable\\.daphen-(?<wt>.+)$") | .wt // empty
        ')
    fi

    if [ -n "$running" ]; then
        printf '{"text": "%s", "class": "lovable", "tooltip": "devenv wt: %s\\nstack: %s"}\n' \
            "$running" "$running" "$active_name"
    elif [ -n "$active_name" ]; then
        printf '{"text": "", "class": "lovable", "tooltip": "stack: %s (no devenv wt running)"}\n' \
            "$active_name"
    else
        printf '{"text": "", "class": "lovable", "tooltip": "lovable workspace"}\n'
    fi
    exit 0
fi

# ── Default minimap (non-lovable workspaces) ─────────────────────────────
if [ -z "$focused_col" ]; then
    echo '{"text": "◆", "tooltip": "No active window"}'
    exit 0
fi

# Distinct column indices of windows on this workspace
mapfile -t cols < <(niri msg --json windows 2>/dev/null \
    | jq -r --argjson ws "$focused_ws_id" '
        [ .[]
          | select(.workspace_id == $ws)
          | .layout.pos_in_scrolling_layout[0]
        ]
        | unique
        | .[]
    ')

if [ "${#cols[@]}" -le 1 ]; then
    echo '{"text": "◆", "tooltip": "Single column"}'
    exit 0
fi

minimap=""
for c in "${cols[@]}"; do
    if [ "$c" -eq "$focused_col" ]; then
        minimap+="◆"
    else
        minimap+="◇"
    fi
done

last_col=${cols[-1]}
printf '{"text": "%s", "tooltip": "WS %s - Col %s/%s"}\n' \
    "$minimap" "$focused_ws_id" "$focused_col" "$last_col"
