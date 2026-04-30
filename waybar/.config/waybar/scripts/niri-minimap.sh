#!/usr/bin/env bash
# Waybar center-module:
# - On a "lovable-<stack>" workspace: emit class "lovable" + the
#   worktree currently running in that workspace's devenv terminal,
#   plus a row of pills (one per stack, filled = focused).
# - Elsewhere: a column-position minimap (◆ for the focused column,
#   ◇ for siblings) — "◆" alone when there are 0/1 columns.
#
# Always emits non-empty text so the waybar center container never
# collapses to an empty box (overlays like screenshot UI or floating
# pickers like rofi can leave focused-window null but the focused
# workspace is always knowable).

set -euo pipefail

workspaces_json=$(niri msg --json workspaces 2>/dev/null || echo "[]")
windows_json=$(niri msg --json windows 2>/dev/null || echo "[]")

# Focused workspace — works whether or not there's a focused window.
# (Niri picks one workspace per output as focused; one of those is the
# one currently focused overall.)
read -r focused_ws_id focused_ws_name < <(echo "$workspaces_json" \
    | jq -r '[.[] | select(.is_focused == true)] | .[0]
             | "\(.id // 0) \(.name // "")"')

# Pills row: one per lovable-<name> stack (excluding lovable / lovable-deps),
# ordered by idx. Filled = focused workspace. Emits empty string when
# there are no stacks.
pills=$(echo "$workspaces_json" | jq -r --argjson focused_id "${focused_ws_id:-0}" '
    [ .[]
      | select((.name // "") | test("^lovable-"))
      | select((.name // "") != "lovable-deps")
    ]
    | sort_by(.idx)
    | map(if .id == $focused_id then "PILL_ON" else "PILL_OFF" end)
    | join(" ")
')
pills=${pills//PILL_ON/●}
pills=${pills//PILL_OFF/○}

# ── Lovable per-workspace stack branch ───────────────────────────────────
if [[ "$focused_ws_name" =~ ^lovable-(.+)$ ]] && [ "${BASH_REMATCH[1]}" != "deps" ]; then
    stack_name="${BASH_REMATCH[1]}"

    # Devenv-running terminal on this workspace (any kitty class) — pull
    # the worktree out of the process-compose title.
    running=$(echo "$windows_json" | jq -r --argjson ws "$focused_ws_id" '
        [ .[]
          | select(.workspace_id == $ws)
          | select((.title // "") | test("^process-compose: proart/lovable\\.daphen-"))
        ]
        | .[0].title // ""
        | capture("^process-compose: proart/lovable\\.daphen-(?<wt>.+)$") | .wt // empty
    ')

    label=${running:-$stack_name}
    if [ -n "$pills" ]; then
        text="$label  $pills"
    else
        text="$label"
    fi

    if [ -n "$running" ]; then
        tooltip="devenv wt: $running\\nstack: $stack_name"
    else
        tooltip="stack: $stack_name (no devenv wt running)"
    fi
    printf '{"text": "%s", "class": "lovable", "tooltip": "%s"}\n' "$text" "$tooltip"
    exit 0
fi

# ── Default: column-position minimap ─────────────────────────────────────
# Distinct column indices of TILED windows on the focused workspace.
mapfile -t cols < <(echo "$windows_json" | jq -r --argjson ws "${focused_ws_id:-0}" '
    [ .[]
      | select(.workspace_id == $ws)
      | select(.is_floating != true)
      | .layout.pos_in_scrolling_layout[0]
      | select(. != null)
    ]
    | unique
    | .[]
')

# Focused column — only meaningful when the focused window itself is
# tiled (not a float/overlay/picker). Falls back to 0 (no highlight).
focused_col=$(echo "$windows_json" | jq -r --argjson ws "${focused_ws_id:-0}" '
    [ .[]
      | select(.workspace_id == $ws and .is_focused == true and .is_floating != true)
    ]
    | .[0].layout.pos_in_scrolling_layout[0] // 0
')

if [ "${#cols[@]}" -le 1 ]; then
    if [ "${#cols[@]}" -eq 0 ]; then
        tooltip="Empty workspace"
    else
        tooltip="Single column"
    fi
    printf '{"text": "◆", "tooltip": "%s"}\n' "$tooltip"
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
