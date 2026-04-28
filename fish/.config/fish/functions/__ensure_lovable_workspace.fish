function __ensure_lovable_workspace --description "Focus or create the niri 'lovable' workspace, pinned to top of the workspace list"
    # If a workspace named "lovable" already exists, just focus it.
    if niri msg --json workspaces 2>/dev/null \
            | jq -e '.[] | select(.name == "lovable")' >/dev/null 2>&1
        niri msg action focus-workspace lovable
        echo exists
        return 0
    end

    # Otherwise: find any empty, unnamed workspace, focus it, give it a name.
    set -l empty_idx (niri msg --json workspaces 2>/dev/null \
        | jq -r '.[] | select(.active_window_id == null and .name == null) | .idx' \
        | head -1)

    if test -n "$empty_idx"
        niri msg action focus-workspace $empty_idx
    else
        niri msg action focus-workspace-down
    end
    sleep 0.1

    niri msg action set-workspace-name lovable

    # Move the newly-created lovable workspace to the top of the workspace list
    # (idx 1) by walking it up. Bound the loop so we don't spin forever if niri
    # disagrees about indices.
    for i in (seq 1 20)
        set -l current_idx (niri msg --json workspaces 2>/dev/null \
            | jq -r '.[] | select(.is_focused == true) | .idx')
        if test -z "$current_idx"; or test "$current_idx" = "1"
            break
        end
        niri msg action move-workspace-up
        sleep 0.05
    end

    echo created
end
