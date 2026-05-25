function hunkr --description "Open hunk reviewing the current branch — auto-detects work branch + base"
    # Default to ~/lovable on the LoL sandbox; respect explicit cwd elsewhere.
    if test -d ~/lovable -a -z "$argv"
        cd ~/lovable
    end

    set -l cur (git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test -z "$cur"
        echo "hunkr: not inside a git repo"
        return 1
    end

    # Lovable parks the SSH'd shell on a per-session 'edit/edt-*' branch
    # that has no real commits. Hop to the most-recent named work branch
    # (daphen/* by convention) so the diff is against actual work.
    if string match -q 'edit/edt-*' -- "$cur"
        set -l named (git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/daphen 2>/dev/null | head -1)
        if test -n "$named"
            git checkout "$named" 2>&1 | tail -1
            set cur "$named"
        else
            echo "hunkr: no daphen/* branch found, staying on $cur"
        end
    end

    # Find the base. Lovable's init commit is the most reliable anchor —
    # marked with '[skip lovable] Initialize Lovable project' on every
    # LoL repo. Fall back to the root commit if not found.
    set -l base (git log --all --grep='\[skip lovable\] Initialize Lovable project' --format='%H' | head -1)
    if test -z "$base"
        set base (git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
    end
    if test -z "$base"
        echo "hunkr: couldn't infer base commit, falling back to working-tree diff"
        hunk diff --watch $argv
        return
    end

    set -l ahead (git rev-list --count "$base..HEAD" 2>/dev/null)
    echo "→ branch: $cur  base: "(string sub -l 8 "$base")"  commits ahead: $ahead"
    hunk diff "$base..HEAD" --watch $argv
end
