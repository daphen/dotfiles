function lovssh --description "SSH into the existing lovbox for a Lovable project URL or claim, with portable dev env"
    set -l input $argv[1]

    # No-arg mode: infer the claim from the current niri workspace name.
    # ws-createlovbox writes claim → short-name to names.json when it
    # provisions; if the focused workspace is `lovable-<short>` and we
    # find a matching entry, use that claim. Skips silently if niri or
    # the mapping aren't available — falls through to the usage error.
    if test -z "$input"
        set -l fw_id (niri msg --json focused-window 2>/dev/null | jq -r '.workspace_id // empty')
        set -l ws_name ""
        if test -n "$fw_id"
            set ws_name (niri msg --json workspaces 2>/dev/null | jq -r --argjson id "$fw_id" '.[] | select(.id == $id) | .name // empty')
        end
        set -l names_file "$HOME/.local/state/lovssh/names.json"
        if string match -q 'lovable-*' -- "$ws_name"; and test -f "$names_file"
            set -l short_name (string sub --start 9 -- "$ws_name")
            # tail -1: when a short-name maps to multiple claims (old sandbox
            # still labeled, new sandbox replacing it), pick the most-recently-
            # added entry. The old one is still resolvable via explicit claim.
            set -l inferred (jq -r --arg n "$short_name" 'to_entries[] | select(.value == $n) | .key' "$names_file" 2>/dev/null | tail -1)
            if test -n "$inferred"
                set input "$inferred"
                echo "→ inferred from workspace $ws_name: claim $inferred"
            end
        end
    end

    if test -z "$input"
        echo "Usage: lovssh <lovable-project-url-or-claim-name>"
        echo "  lovssh https://lovable.dev/projects/<uuid>"
        echo "  lovssh lovable-<16hex>"
        echo "  lovssh daphen-<scratch-name>"
        echo "  lovssh   (no args, infers from current niri workspace)"
        return 1
    end

    set -l lovbox_bin ~/work/lovable/bin/lovbox
    if not test -x "$lovbox_bin"
        echo "✗ lovbox CLI not found at $lovbox_bin"
        echo "  Build it from ~/work/lovable/go/lovbox/cmd/lovbox or rebuild your lov toolchain."
        return 1
    end

    # Resolve claim: accept a claim directly (lovable-* / daphen-*), or extract a
    # project UUID from a URL and derive the deterministic L-on-L claim from it.
    set -l claim
    set -l project_id ""
    if string match -q 'lovable-*' -- "$input"; or string match -q 'daphen-*' -- "$input"
        set claim "$input"
    else
        set project_id (string match -r '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' -- "$input")
        if test -z "$project_id"
            echo "Could not extract a project UUID from: $input"
            return 1
        end
        # sha256(project_id\0main\0lovable-on-lovable)[:16] — matches schedulerTemplateClaimName.
        set claim (env PID="$project_id" python3 -c 'import hashlib, os; pid=os.environ["PID"]; print("lovable-" + hashlib.sha256(f"{pid}\x00main\x00lovable-on-lovable".encode()).hexdigest()[:16])')
        echo "→ Project: $project_id"
    end
    echo "→ Claim:   $claim"

    # Touch this claim's names.json entry so bare-args inference (which does
    # `tail -1`) picks it up next time. Delete + re-insert moves the entry
    # to the end of the dict. Only acts when the claim is already labeled —
    # doesn't auto-create entries (that's ws-createlovbox's job).
    set -l names_file "$HOME/.local/state/lovssh/names.json"
    if test -f "$names_file"
        set -l existing_name (jq -r --arg c "$claim" '.[$c] // empty' "$names_file" 2>/dev/null)
        if test -n "$existing_name"
            set -l tmp (mktemp)
            jq --arg c "$claim" --arg n "$existing_name" 'del(.[$c]) | .[$c] = $n' "$names_file" > "$tmp"
            and mv "$tmp" "$names_file"
        end
    end

    # Delegate sandbox provisioning + SSH-key injection + host discovery to the
    # lovbox CLI. It's Lovable-maintained, sources the direct cluster hostname
    # from the API (so cluster moves don't require a script change), and prints
    # both the direct and gateway candidates. --no-ssh stops short of opening a
    # session so we can run our own connect with the daphen-env bootstrap.
    echo "→ Provisioning via lovbox…"
    set -l raw ($lovbox_bin ssh --name "$claim" --no-ssh 2>&1)
    set -l rc $status
    set -l info (printf '%s\n' $raw | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
    if test $rc -ne 0
        echo "✗ lovbox provisioning failed (exit $rc):"
        printf '%s\n' $info
        return 1
    end

    # Parse out "user@host" from each candidate. lovbox's output format:
    #   Connection info (direct via sandbox service):
    #     ssh -p 2222 lovable@<sandbox>.<ns>.svc.<cluster>.cluster.d.l5e.io
    #   Connection info (via gateway):
    #     ssh -p 2222 <claim>@sandcastle.lovable.net
    set -l direct_target (printf '%s\n' $info | awk '
        /Connection info \(direct via sandbox service\)/ { found=1; next }
        found && /ssh -p/ { print $NF; exit }
    ')
    set -l gateway_target (printf '%s\n' $info | awk '
        /Connection info \(via gateway\)/ { found=1; next }
        found && /ssh -p/ { print $NF; exit }
    ')

    set -l candidates
    test -n "$direct_target"; and set -a candidates "$direct_target"
    test -n "$gateway_target"; and set -a candidates "$gateway_target"
    if test (count $candidates) -eq 0
        echo "✗ Couldn't extract any SSH targets from lovbox output:"
        printf '%s\n' $info
        return 1
    end

    echo "✓ Sandbox ready, SSH key injected"
    for t in $candidates
        echo "  • $t"
    end

    # Best-effort: capture work-branch refs from the sandbox for rofi-lovbox-jump's
    # personal-history filter. Cap at 5s so a slow sandbox doesn't stall connect.
    # Try gateway first (more reliable from outside-cluster), fall back to direct.
    set -l refs_cmd '(git -C ~/lovable for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/daphen 2>/dev/null | head -1; git -C ~/lovable branch --show-current 2>/dev/null) | paste -sd "|"'
    set -l refs ""
    set -l history_order $gateway_target $direct_target
    for t in $history_order
        if test -z "$t"; continue; end
        set -l out (timeout 5 ssh -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null -o BatchMode=yes \
            -o ConnectTimeout=5 -p 2222 "$t" "$refs_cmd" 2>/dev/null; or true)
        if test -n "$out"
            set refs "$out"
            break
        end
    end
    set -l daphen_branch (string split '|' -- $refs)[1]
    set -l branch (string split '|' -- $refs)[2]
    set -l history_file "$HOME/.local/state/lovssh/history.jsonl"
    mkdir -p (dirname "$history_file")
    set -l now (date -u +%Y-%m-%dT%H:%M:%SZ)
    printf '{"timestamp":"%s","claim":"%s","project_id":"%s","input":"%s","branch":"%s","daphen_branch":"%s"}\n' \
        "$now" "$claim" "$project_id" "$input" "$branch" "$daphen_branch" >> "$history_file"

    # Pass proart's theme to the sandbox so starship/nvim pick the matching
    # variant at connect. nvim's fs_event watcher on theme_mode reacts live
    # to later toggles via the in-sandbox toggle_theme function.
    set -l proart_theme (cat ~/.config/theme_mode 2>/dev/null; or echo light)

    # Look up the human short-name for this claim so starship can display it
    # in the prompt as "ssh <short>". Falls back to the claim hex if unmapped.
    set -l sandbox_label "$claim"
    set -l names_file "$HOME/.local/state/lovssh/names.json"
    if test -f "$names_file"
        set -l mapped (jq -r --arg c "$claim" '.[$c] // empty' "$names_file" 2>/dev/null)
        if test -n "$mapped"
            set sandbox_label "$mapped"
        end
    end

    # Notes-memory MCP token: pulled from 1Password at SSH-time, injected
    # into the session env via the remote command (never written to the
    # sandbox filesystem). Each SSH session gets its own bearer; coworkers
    # SSHing in see no token. If 1Password isn't reachable or the item is
    # missing, the sandbox shell just won't have MCP — non-fatal.
    set -l notes_token (op read 'op://Private/notes-memory-mcp/password' 2>/dev/null)
    set -l token_export ""
    if test -n "$notes_token"
        set token_export "export NOTES_MEMORY_TOKEN='$notes_token'; "
    end

    # Remote bootstrap: write theme, export SANDBOX_LABEL for the prompt,
    # then exec daphen-env. First run builds the closure (~2 min); subsequent
    # runs are instant. --refresh ignores the 1h flake registry cache so
    # freshly-pushed dotfiles land immediately.
    # Single-line ';' chain because the lovbox sshd truncates multi-line args.
    set -l remote_cmd "$token_export""export TERM=xterm-256color SANDBOX_LABEL='$sandbox_label'; echo '[lovssh] connected as '\$(whoami)'@'\$(hostname); mkdir -p ~/.config; echo '$proart_theme' > ~/.config/theme_mode; echo '[lovssh] theme: $proart_theme'; cd ~/lovable 2>/dev/null; echo '[lovssh] launching dev env via nix run...'; exec nix run --refresh --option require-sigs false github:daphen/nixos-portable-config#daphen-env"

    # Pre-seed the sandbox's nix store from proart. The cluster cache misses
    # most of our env closure, so a fresh sandbox compiles neovim from source
    # (~10 min); pushing proart's already-built paths turns that into a
    # transfer. Every failure here is non-fatal — remote nix run still works,
    # just slower.
    echo "[lovssh] resolving env closure locally…"
    set -l env_path (nix build --no-link --print-out-paths github:daphen/nixos-portable-config#daphen-env 2>/dev/null | tail -1)
    if test -n "$env_path"
        for t in $candidates
            echo "[lovssh] pre-seeding nix store on $t…"
            if env NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -p 2222" \
                    nix copy --to "ssh://lovable@$t" "$env_path" 2>/dev/null
                echo "[lovssh] closure pushed"
                break
            end
        end
    end

    # Try direct first (lower latency when DNS works), gateway on failure.
    # Exit 255 = SSH-level connection failure → try the next candidate.
    # Anything else = remote command exit → respect the reconnect loop.
    # ConnectTimeout: short on direct (DNS NXDOMAIN returns instantly, no point
    # waiting); none on gateway, matching lovbox's behavior (gateway can take
    # 30-60s through some routes). ServerAlive keeps idle sessions alive.
    while true
        set -l hit_remote_failure 0
        set -l idx 0
        for target in $candidates
            set idx (math $idx + 1)
            set -l timeout_opt
            if test "$target" = "$direct_target"
                set timeout_opt -o ConnectTimeout=5
            end
            echo "→ Connecting to $target"
            ssh -A -p 2222 -tt \
                -o StrictHostKeyChecking=no \
                -o UserKnownHostsFile=/dev/null \
                $timeout_opt \
                -o ServerAliveInterval=60 \
                -o ServerAliveCountMax=5 \
                "$target" "$remote_cmd"
            set -l rc $status
            if test $rc -eq 0
                return 0
            end
            if test $rc -eq 255
                echo "[lovssh] $target unreachable (exit 255) — trying next"
                continue
            end
            echo "[lovssh] disconnected (exit $rc) — reconnecting in 3s, ctrl-c to abort"
            set hit_remote_failure 1
            break
        end
        if test $hit_remote_failure -eq 1
            sleep 3
        else
            echo "[lovssh] all candidates unreachable — retrying in 5s, ctrl-c to abort"
            sleep 5
        end
    end
end
