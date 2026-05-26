function lovssh --description "SSH into the existing lovbox for a Lovable project URL and install portable dev env"
    set -l input $argv[1]
    if test -z "$input"
        echo "Usage: lovssh <lovable-project-url-or-claim-name>"
        echo "  lovssh https://lovable.dev/projects/<uuid>"
        echo "  lovssh lovable-<16hex>"
        return 1
    end

    # Resolve claim name: accept claim directly, or extract UUID from URL.
    set -l claim
    set -l project_id ""
    if string match -q 'lovable-*' -- "$input"
        set claim "$input"
    else
        set project_id (string match -r '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' -- "$input")
        if test -z "$project_id"
            echo "Could not extract a project UUID from: $input"
            return 1
        end
        # Deterministic claim: sha256(project_id\0main\0lovable-on-lovable), first 16 hex.
        set claim (env PID="$project_id" python3 -c 'import hashlib, os; pid=os.environ["PID"]; print("lovable-" + hashlib.sha256(f"{pid}\x00main\x00lovable-on-lovable".encode()).hexdigest()[:16])')
        echo "→ Project: $project_id"
    end
    echo "→ Claim:   $claim"

    # Look up the sandbox in personal + shared namespaces. We need its
    # sandbox_name + namespace to build the direct service hostname (the
    # gateway sandcastle.lovable.net:2222 is unreliable from outside-cluster).
    set -l sandbox_json ""
    for q in "" "?access=shared"
        set -l body (curl -s "https://sandcastle.lovable.net/api/v1/sandboxes$q")
        set -l match (echo $body | jq -c --arg n "$claim" '.[] | select(.name == $n)' 2>/dev/null)
        if test -n "$match"
            set sandbox_json "$match"
            break
        end
    end
    if test -z "$sandbox_json"
        echo "✗ No running sandbox named $claim."
        echo "  Open the project in lovable.dev to spawn one, then re-run lovssh."
        return 1
    end

    set -l sandbox_name   (echo $sandbox_json | jq -r '.sandbox_name')
    set -l namespace      (echo $sandbox_json | jq -r '.namespace')
    set -l sandbox_status (echo $sandbox_json | jq -r '.status')
    set -l direct_host "$sandbox_name.$namespace.svc.devex-eun2-toad.cluster.d.l5e.io"
    echo "✓ Found sandbox: $sandbox_name (status: $sandbox_status)"
    echo "→ Direct host: $direct_host"

    # Pick an SSH public key to inject.
    set -l pubkey_file ~/.ssh/id_ed25519.pub
    if not test -f $pubkey_file
        set pubkey_file ~/.ssh/id_rsa.pub
    end
    if not test -f $pubkey_file
        echo "✗ No SSH public key found at ~/.ssh/id_ed25519.pub or id_rsa.pub"
        return 1
    end
    set -l pubkey (cat $pubkey_file)

    # Inject pubkey via the lovbox API. Tailnet source IP is the auth.
    set -l inject_status (curl -s -o /dev/null -w "%{http_code}" \
        -X POST "https://sandcastle.lovable.net/api/v1/sandboxes/$claim/ssh-keys" \
        -H "Content-Type: application/json" \
        -d "{\"public_key\":\"$pubkey\"}")
    if not contains "$inject_status" 200 201 204
        echo "✗ Couldn't register SSH key (HTTP $inject_status)."
        return 1
    end
    echo "✓ SSH key registered."

    # Log this visit so `rofi-lovbox-jump` can show your recently-used
    # sandboxes as a "personal" filter on top of the team-wide list.
    # Capture two refs from inside the sandbox in one round-trip:
    #  - daphen_branch: the most-recently-touched daphen/* work branch
    #    (the stable identifier for the ticket — same across edit/edt-*
    #    per-prompt churn)
    #  - branch: HEAD at the moment of SSH (often edit/edt-<uuid>,
    #    useful for the per-session diff but not for identifying work)
    # Capped at 5s so a slow sandbox doesn't delay the SSH session below.
    set -l refs (timeout 5 ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null -o BatchMode=yes \
        -p 2222 "lovable@$direct_host" \
        '(git -C ~/lovable for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/daphen 2>/dev/null | head -1; git -C ~/lovable branch --show-current 2>/dev/null) | paste -sd "|"' \
        2>/dev/null; or true)
    set -l daphen_branch (string split '|' -- $refs)[1]
    set -l branch (string split '|' -- $refs)[2]
    set -l history_file "$HOME/.local/state/lovssh/history.jsonl"
    mkdir -p (dirname "$history_file")
    set -l now (date -u +%Y-%m-%dT%H:%M:%SZ)
    printf '{"timestamp":"%s","claim":"%s","project_id":"%s","input":"%s","branch":"%s","daphen_branch":"%s"}\n' \
        "$now" "$claim" "$project_id" "$input" "$branch" "$daphen_branch" >> "$history_file"

    # Pass proart's current theme through to the sandbox so its starship/
    # nvim spin up matching the local terminal at connect time. Default to
    # "light" if proart's mode file is missing for some reason.
    set -l proart_theme (cat ~/.config/theme_mode 2>/dev/null; or echo light)

    # Connect via the direct service hostname (user = "lovable", not the claim).
    # Inside the sandbox: write the inherited theme, then `nix run` the
    # daphen-env package. First run builds the closure (~2 min); subsequent
    # runs are instant. `--refresh` ignores the 1h flake registry cache so
    # pushes are picked up immediately.
    #
    # Single-line + ';' because the lovbox sshd truncates multi-line
    # arguments. fish double-quotes interpolate $proart_theme.
    # Reconnect loop: SSH returns 0 only on a clean `exit` from inside
    # the sandbox; any disconnect (network blip, sandbox recycle, sshd
    # timeout) returns non-zero, so we retry with a short backoff.
    # ServerAliveInterval+CountMax keeps the connection alive across
    # idle periods so the loop doesn't fire on every minor blip.
    echo "→ Connecting…"
    while true
        ssh -A -p 2222 -t \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=10 \
            -o ServerAliveInterval=60 \
            -o ServerAliveCountMax=5 \
            "lovable@$direct_host" "export TERM=xterm-256color; echo '[lovssh] connected as '\$(whoami)'@'\$(hostname); mkdir -p ~/.config; echo '$proart_theme' > ~/.config/theme_mode; echo '[lovssh] theme: $proart_theme'; cd ~/lovable 2>/dev/null; echo '[lovssh] launching dev env via nix run...'; exec nix run --refresh --option require-sigs false github:daphen/nixos-portable-config#daphen-env"
        set -l rc $status
        if test $rc -eq 0
            break
        end
        echo "[lovssh] disconnected (exit $rc) — reconnecting in 3s, ctrl-c to abort"
        sleep 3
    end
end
