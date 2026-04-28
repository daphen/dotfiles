function __wt_spawn_and_merge --description "Spawn a command, wait for its niri window, and merge it into a specific existing column by index"
    # usage: __wt_spawn_and_merge <target_col_idx> <command-string>
    #   target_col_idx = 0 → no merge (first worktree, just spawn)
    #   target_col_idx = 1/2/3 → merge into col 1/2/3 (term/browser/claude)
    set -l target_col $argv[1]
    set -l cmd $argv[2]

    set -l before_ids (niri msg --json windows 2>/dev/null | jq -r '.[].id')
    # setsid detaches the child into its own session so it survives the
    # caller (e.g. a rofi-spawned picker kitty closing).
    eval "setsid $cmd >/dev/null 2>&1 < /dev/null &"
    disown 2>/dev/null

    # Poll for the new window ID
    set -l new_id ""
    for i in (seq 1 60)
        sleep 0.15
        set -l current_ids (niri msg --json windows 2>/dev/null | jq -r '.[].id')
        for cid in $current_ids
            if not contains -- $cid $before_ids
                set new_id $cid
                break
            end
        end
        test -n "$new_id"; and break
    end

    if test -z "$new_id"
        echo "  !! couldn't find new window for: $cmd" >&2
        set -g __WT_LAST_SPAWNED_ID ""
        return 1
    end

    echo "  ↳ new window id=$new_id"
    # Expose the new ID so the caller can save it to the worktree state file
    set -g __WT_LAST_SPAWNED_ID $new_id

    # First-worktree case — no merge, leave the column where niri put it
    if test "$target_col" -eq 0
        return 0
    end

    # Make sure niri has focused the new window before we move its column
    niri msg action focus-window --id $new_id
    sleep 0.15

    # Move the new window's column to be at position (target_col + 1), so it
    # sits immediately to the right of the target column.
    set -l adjacent_idx (math $target_col + 1)
    echo "  ↳ moving new column to index $adjacent_idx (right of target col $target_col)"
    niri msg action move-column-to-index $adjacent_idx
    sleep 0.15

    # Focus the target column, then consume the window now sitting to its right
    echo "  ↳ focusing target col $target_col, consuming right neighbor"
    niri msg action focus-column $target_col
    sleep 0.15
    niri msg action consume-window-into-column
    sleep 0.15

    return 0
end
