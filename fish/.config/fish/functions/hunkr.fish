function hunkr --description "Open hunk reviewing the daphen/* work branch — pinned to ref, so Lovable's per-session edit/edt-* HEAD churn doesn't blank the diff"
    # Default to ~/lovable on the LoL sandbox; respect explicit cwd elsewhere.
    if test -d ~/lovable -a -z "$argv"
        cd ~/lovable
    end

    set -l cur (git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test -z "$cur"
        echo "hunkr: not inside a git repo"
        return 1
    end

    # Find the most-recently-touched daphen/* branch and pin the diff to
    # that ref. Lovable creates a fresh edit/edt-<uuid> branch every chat
    # turn and checks it out in the shared sandbox working tree; if we
    # diff against HEAD we lose the work-branch view every time. Pinning
    # to refs/heads/daphen/* means HEAD can wander all it wants.
    set -l work (git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/daphen 2>/dev/null | head -1)
    if test -z "$work"
        echo "hunkr: no daphen/* branch — falling back to HEAD ($cur)"
        set work HEAD
    end

    # Find the base. Lovable's init commit is the most reliable anchor —
    # marked with '[skip lovable] Initialize Lovable project'. Fall back
    # to the work branch's root commit if not found.
    set -l base (git log --all --grep='\[skip lovable\] Initialize Lovable project' --format='%H' | head -1)
    if test -z "$base"
        set base (git rev-list --max-parents=0 "$work" 2>/dev/null | head -1)
    end
    if test -z "$base"
        echo "hunkr: couldn't infer base commit, falling back to working-tree diff"
        hunk diff --watch $argv
        return
    end

    set -l ahead (git rev-list --count "$base..$work" 2>/dev/null)
    if test "$cur" != "$work"
        echo "→ pinned: $work  HEAD: $cur  base: "(string sub -l 8 "$base")"  commits: $ahead"
    else
        echo "→ branch: $work  base: "(string sub -l 8 "$base")"  commits: $ahead"
    end
    hunk diff "$base..$work" --watch $argv
end
