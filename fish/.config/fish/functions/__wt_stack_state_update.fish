function __wt_stack_state_update --description "Append/update a worktree's 3 window IDs in the wt-stacks state file"
    set -l name $argv[1]
    set -l term_id $argv[2]
    set -l browser_id $argv[3]
    set -l claude_id $argv[4]

    set -l state_dir "$HOME/.local/state/wt-stacks"
    set -l state_file "$state_dir/lovable.json"

    mkdir -p $state_dir
    if not test -f $state_file
        echo '{"worktrees":[]}' > $state_file
    end

    # Remove any existing entry for this name, then append the fresh entry
    set -l tmp (mktemp)
    jq --arg name "$name" \
       --argjson term "$term_id" \
       --argjson browser "$browser_id" \
       --argjson claude "$claude_id" \
       '.worktrees |= map(select(.name != $name)) | .worktrees += [{"name": $name, "term_id": $term, "browser_id": $browser, "claude_id": $claude}]' \
       $state_file > $tmp; and mv $tmp $state_file

    echo "==> state updated: $name → term=$term_id browser=$browser_id claude=$claude_id"
end
