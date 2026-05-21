function lovlist --description "List lovable-on-lovable sandboxes (your project sandboxes)"
    # Default: show only lovable-<16hex> sandboxes (project sandboxes you'd
    # actually lovssh into), most-recent 30, sorted newest first.
    # Flags:
    #   -a / --all       show everything (br-*, sandbox-*, dev-*, user-named)
    #   -n / --limit N   max rows (default 30; 0 = no limit)
    #   -p / --powerplay only powerplay branch sandboxes (br-*)
    argparse 'a/all' 'p/powerplay' 'n/limit=!_validate_int' -- $argv
    or return

    set -l limit 30
    if set -q _flag_limit
        set limit $_flag_limit
    end

    # Fetch personal + shared (lovable-on-lovable ones land in shared).
    set -l personal (curl -s "https://sandcastle.lovable.net/api/v1/sandboxes")
    set -l shared   (curl -s "https://sandcastle.lovable.net/api/v1/sandboxes?access=shared")

    set -l merged (echo "$personal $shared" | jq -s '
        ([.[0][]?, .[1][]?] | unique_by(.name))
    ')

    # Build a jq filter. Default: only "lovable-<16hex>" (project sandboxes).
    # --powerplay: only "br-*". --all: pass everything through.
    set -l filter '.[]'
    if set -q _flag_all
        # no name filter
    else if set -q _flag_powerplay
        set filter '.[] | select(.name | startswith("br-"))'
    else
        # lovable-on-lovable project sandboxes are "lovable-<16 hex digits>".
        # Exclude templates, threads, and user-named scratch sandboxes.
        set filter '.[] | select(.name | test("^lovable-[0-9a-f]{16}$"))'
    end

    set -l rows (echo $merged | jq -r "
        [$filter] |
        sort_by(.creation_time) | reverse |
        .[] |
        [.name, .status, (.project_id // \"?\"), .creation_time] |
        @tsv
    ")

    set -l n (count $rows)
    if test $n -eq 0
        echo "No matching sandboxes found."
        return 0
    end

    # Apply limit (0 = unlimited).
    if test $limit -gt 0 -a $n -gt $limit
        set rows $rows[1..$limit]
        printf "%s\n" $rows | column -t -s \t -N CLAIM,STATUS,PROJECT,CREATED
        echo
        echo "($limit of $n shown — use 'lovlist -n 0' for all, 'lovlist -a' for everything including br-* / scratch)"
    else
        printf "%s\n" $rows | column -t -s \t -N CLAIM,STATUS,PROJECT,CREATED
    end
end
