function lov-name --description "Attach a human-readable label to a lovbox claim (shown by rofi-lovbox-jump / Super+B)"
    set -l claim_or_url $argv[1]
    set -l label $argv[2..-1]

    if test -z "$claim_or_url"
        echo "Usage: lov-name <claim-or-url> <label words...>"
        echo "Examples:"
        echo "  lov-name lovable-fb69e06195a7297e 'jacobs todo app'"
        echo "  lov-name https://lovable.dev/projects/f6180715-... 'jacobs todo app'"
        echo
        echo "List current labels:  lov-name --list"
        echo "Remove a label:       lov-name --rm <claim-or-url>"
        return 1
    end

    set -l names_file "$HOME/.local/state/lovssh/names.json"
    mkdir -p (dirname "$names_file")
    test -f "$names_file"; or echo '{}' > "$names_file"

    if test "$claim_or_url" = "--list"
        jq -r 'to_entries | sort_by(.key) | .[] | "\(.key)\t\(.value)"' "$names_file" | column -t -s \t -N CLAIM,LABEL
        return 0
    end

    if test "$claim_or_url" = "--rm"
        set -l target $argv[2]
        if test -z "$target"
            echo "Usage: lov-name --rm <claim-or-url>"
            return 1
        end
        set -l claim (_lov_claim_from "$target"); or return 1
        set -l tmp (mktemp)
        jq --arg c "$claim" 'del(.[$c])' "$names_file" > "$tmp"
        and mv "$tmp" "$names_file"
        and echo "✓ removed label for $claim"
        return 0
    end

    if test (count $label) -eq 0
        echo "Need a label after the claim/url."
        return 1
    end

    set -l claim (_lov_claim_from "$claim_or_url"); or return 1
    set -l label_str (string join " " $label)

    set -l tmp (mktemp)
    jq --arg c "$claim" --arg l "$label_str" '.[$c] = $l' "$names_file" > "$tmp"
    and mv "$tmp" "$names_file"
    and echo "✓ $claim → $label_str"
end

# Helper: turn a URL or claim into a claim name. Mirrors the resolver in
# lovssh.fish. Echoes the claim on success, returns nonzero on failure.
function _lov_claim_from
    set -l input $argv[1]
    if string match -q 'lovable-*' -- "$input"
        echo "$input"
        return 0
    end
    set -l project_id (string match -r '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' -- "$input")
    if test -z "$project_id"
        echo "Couldn't extract a project UUID or claim from: $input"
        return 1
    end
    env PID="$project_id" python3 -c 'import hashlib, os; pid=os.environ["PID"]; print("lovable-" + hashlib.sha256(f"{pid}\x00main\x00lovable-on-lovable".encode()).hexdigest()[:16])'
end
