function createwt --description "Create or switch to a Lovable worktree + spawn its app stack on niri workspace 'lovable'"
    set -l name $argv[1]
    if test -z "$name"
        echo "usage: createwt <branch-name>" >&2
        return 1
    end

    set -l workspace "lovable"
    set -l lovable_dir "$HOME/work/lovable"
    # Lovable convention: branches are namespaced under daphen/, worktrees land
    # at lovable.daphen-<short-name>.
    set -l branch "daphen/$name"
    set -l worktree_path "$HOME/work/lovable.daphen-$name"
    set -l preview_url "http://daphen-$name.localhost:2015"

    # 1. Create the worktree (or switch if it exists)
    pushd "$lovable_dir" >/dev/null
    if test -d "$worktree_path"
        echo "==> Worktree '$branch' already exists — switching"
        command wt switch "$branch"
    else
        echo "==> Creating worktree '$branch'"
        command wt switch --create "$branch"
    end
    popd >/dev/null

    # 2. Detect whether the lovable workspace already has windows.
    # If empty: this is the first worktree, just spawn into 3 fresh columns.
    # If populated: we need to merge new spawns into the existing 3 columns.
    set -l existing (niri msg --json windows | jq -r --arg ws "$workspace" '
        [.[] | select(.workspace_id != null)] | length' 2>/dev/null; or echo 0)

    # Robust workspace detection: count windows whose workspace name == "lovable"
    set -l existing_count (niri msg --json windows 2>/dev/null \
        | jq -r --arg ws "$workspace" \
              '[.[] | . as $w | $w.workspace_id as $wid
                | (input_filename // empty) | empty,
                empty]
              | length' 2>/dev/null; or echo 0)

    # Resolve lovable workspace id and inspect what's already there.
    # `lovable_deps` (if running) sits at col 1, shifting stack columns by 1.
    set -l ws_id (niri msg --json workspaces 2>/dev/null \
        | jq -r --arg n "$workspace" '.[] | select(.name == $n) | .id' \
        | head -1)
    set -l existing_terms 0
    set -l deps_present 0
    if test -n "$ws_id"
        # Match per-stack tagged classes: lovable_term_<name>
        set existing_terms (niri msg --json windows 2>/dev/null \
            | jq -r --arg id "$ws_id" '[.[] | select(.workspace_id == ($id|tonumber) and ((.app_id // "") | startswith("lovable_term_")))] | length')
        set deps_present (niri msg --json windows 2>/dev/null \
            | jq -r --arg id "$ws_id" '[.[] | select(.workspace_id == ($id|tonumber) and .app_id == "lovable_deps")] | length')
    end

    # 3. Resolve claude session mode UPFRONT, before any spawning. Inline
    # fzf prompts mid-spawn pull focus to the picker kitty (which lives on
    # the user's original workspace), causing subsequent spawns to land on
    # the wrong workspace and breaking the merge.
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

    # 4. Ensure the lovable workspace exists. Deps is no longer auto-started
    # here — start it on demand via Super+M (devenv wt requires deps already
    # running, so a race-prone auto-spawn caused term to fail and close).
    __ensure_lovable_workspace

    # 4. Spawn the three stack apps.
    #
    # Layout convention (left-to-right):
    #   [optional] devenv deps (lovable singleton, col 1 if running)
    #   devenv terminals (kitty `direnv exec . devenv wt`)
    #   vivaldi work-profile windows
    #   claude sessions (kitty -e claude)

    set -l is_first 1
    if test $existing_terms -gt 0
        set is_first 0
    end

    # offset: deps occupies col 1 → shift stack indices by 1 when present.
    set -l offset 0
    if test "$deps_present" != "0"
        set offset 1
    end

    # target_col=0 → first worktree, no merge (4 fresh columns spawn naturally)
    # target_col=(1+offset)/(2+offset)/(3+offset)/(4+offset) → merge into existing columns
    set -l target_term 0
    set -l target_browser 0
    set -l target_claude 0
    set -l target_nvim 0
    if test $is_first -eq 0
        set target_term (math 1 + $offset)
        set target_browser (math 2 + $offset)
        set target_claude (math 3 + $offset)
        set target_nvim (math 4 + $offset)
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

    echo "==> spawning nvim in $worktree_path"
    __wt_spawn_and_merge $target_nvim "kitty --class lovable_nvim_$name --working-directory '$worktree_path' -e bash -c 'nvim; exec fish'"
    set -l nvim_id $__WT_LAST_SPAWNED_ID

    # Land focus on the new worktree's claude
    if test -n "$claude_id"
        niri msg action focus-window --id $claude_id
    end

    echo "==> Worktree '$name' ready on niri workspace '$workspace'"
    if test $is_first -eq 1
        echo "    First worktree on this workspace — 3 columns, each in tabbed mode."
        echo "    Subsequent createwt calls will stack new tabs into these columns."
    else
        echo "    Stacked onto existing columns. Super+Up/Down walks each column's tabs."
    end
end
