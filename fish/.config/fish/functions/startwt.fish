function startwt --description "Pick an existing Lovable worktree and spawn its app stack on niri workspace 'lovable'"
    # Get list of existing worktrees, exclude the primary "lovable" tree itself
    set -l choices (git -C $HOME/work/lovable worktree list --porcelain 2>/dev/null \
        | awk '/^worktree / {p=$2} /^branch / {b=$2; if (p !~ /lovable$/) print b "\t" p}' \
        | sed 's|refs/heads/||')

    if test -z "$choices"
        echo "no worktrees found in ~/work/lovable" >&2
        return 1
    end

    # fzf picker — show branch + path
    set -l picked (printf '%s\n' $choices | fzf \
        --prompt="worktree> " \
        --with-nth=1 \
        --delimiter='\t' \
        --preview='echo "branch: {1}"; echo "path: {2}"; echo; ls -la {2} 2>/dev/null | head -20' \
        --height=60% --reverse)

    if test -z "$picked"
        return 1
    end

    set -l branch (echo $picked | cut -f1)
    set -l worktree_path (echo $picked | cut -f2)

    # Derive a "name" arg compatible with createwt's URL convention.
    # Branch like "daphen/foo" → name "foo"; bare "foo" → "foo".
    set -l name (echo $branch | sed 's|^daphen/||')

    set -l workspace "lovable"
    set -l preview_url "https://daphen-$name.localhost:2015"

    # Note: we don't `wt switch` here — the worktree exists, we have the path,
    # and all spawned terminals get --working-directory anyway. No cd needed.

    # Resolve lovable workspace id and inspect what's already there.
    set -l ws_id (niri msg --json workspaces 2>/dev/null \
        | jq -r --arg n "$workspace" '.[] | select(.name == $n) | .id' | head -1)
    set -l existing_terms 0
    set -l deps_present 0
    if test -n "$ws_id"
        # Match per-stack tagged classes: lovable_term_<name>
        set existing_terms (niri msg --json windows 2>/dev/null \
            | jq -r --arg id "$ws_id" '[.[] | select(.workspace_id == ($id|tonumber) and ((.app_id // "") | startswith("lovable_term_")))] | length')
        set deps_present (niri msg --json windows 2>/dev/null \
            | jq -r --arg id "$ws_id" '[.[] | select(.workspace_id == ($id|tonumber) and .app_id == "lovable_deps")] | length')
    end

    set -l is_first 1
    if test $existing_terms -gt 0
        set is_first 0
    end

    # Resolve claude session mode UPFRONT, before any spawning. Inline fzf
    # prompts mid-spawn pull focus to the picker kitty (which lives on the
    # user's original workspace), causing subsequent spawns to land on the
    # wrong workspace and breaking the merge.
    set -l claude_inner "claude"
    set -l mode (printf '%s\n' new resume fork \
        | fzf --prompt="claude session> " --height=8 --reverse --no-sort)
    test -z "$mode"; and set mode new
    if test "$mode" != "new"
        set -l session_id ($HOME/.config/niri/scripts/spawn-claude-session-picker --id-only)
        if test -n "$session_id"
            if test "$mode" = "fork"
                set claude_inner "claude --resume $session_id --fork-session"
            else
                set claude_inner "claude --resume $session_id"
            end
        end
    end

    # Ensure lovable workspace exists. Deps is no longer auto-started here —
    # start it on demand via Super+M; otherwise devenv wt would race against
    # an unready deps and exit.
    __ensure_lovable_workspace

    # offset: deps occupies col 1 → shift stack indices by 1 when present.
    set -l offset 0
    if test "$deps_present" != "0"
        set offset 1
    end

    set -l target_term 0
    set -l target_browser 0
    set -l target_claude 0
    if test $is_first -eq 0
        set target_term (math 1 + $offset)
        set target_browser (math 2 + $offset)
        set target_claude (math 3 + $offset)
    end

    echo "==> spawning devenv wt in $worktree_path"
    # bash wraps so the kitty drops into an interactive fish after devenv wt
    # exits (Ctrl+C, error, etc), letting the user cd to another worktree
    # and re-run without losing the stack window.
    __wt_spawn_and_merge $target_term "kitty --class lovable_term_$name --working-directory '$worktree_path' -e bash -c 'direnv exec . devenv wt; exec fish'"
    set -l term_id $__WT_LAST_SPAWNED_ID

    echo "==> spawning vivaldi (Work profile) → $preview_url"
    __wt_spawn_and_merge $target_browser "/run/current-system/sw/bin/vivaldi --profile-directory='Profile 2' --new-window '$preview_url'"
    set -l browser_id $__WT_LAST_SPAWNED_ID
    if test -n "$browser_id"
        __wt_vivaldi_map_save $name $browser_id
    end

    echo "==> spawning claude session ($mode)"
    __wt_spawn_and_merge $target_claude "kitty --class lovable_claude_$name --working-directory '$worktree_path' -e $claude_inner"
    set -l claude_id $__WT_LAST_SPAWNED_ID

    # Land focus on the new worktree's claude
    if test -n "$claude_id"
        niri msg action focus-window --id $claude_id
    end

    echo "==> Worktree '$branch' ready on niri workspace '$workspace'"
end
