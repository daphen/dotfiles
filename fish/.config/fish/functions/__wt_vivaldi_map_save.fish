function __wt_vivaldi_map_save --description "Persist a vivaldi window_id → stack_name mapping so the focus-tracker sync can find the right vivaldi even if the user navigates it away from the daphen-<name>.localhost URL"
    set -l name $argv[1]
    set -l wid $argv[2]

    if test -z "$name"; or test -z "$wid"
        return 1
    end

    set -l file $HOME/.local/state/wt-stacks/vivaldi-map.json
    mkdir -p (dirname $file)
    if not test -f $file
        echo '{}' > $file
    end

    # Prune entries whose window no longer exists, then add this one.
    set -l live_ids (niri msg --json windows 2>/dev/null | jq -r '[.[].id | tostring] | join(",")')
    set -l updated (jq --arg n "$name" --arg id "$wid" --arg live "$live_ids" '
        ($live | split(",")) as $alive
        | (with_entries(select(.key | IN($alive[]))))
        + {($id): $n}
    ' $file)
    echo $updated > $file
end
