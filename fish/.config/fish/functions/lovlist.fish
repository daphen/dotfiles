function lovlist --description "List lovable-on-lovable sandboxes (your project sandboxes)"
    # Default: show only lovable-<16hex> sandboxes (project sandboxes you'd
    # actually lovssh into), most-recent 30, sorted newest first.
    # Flags:
    #   -a / --all              show everything (br-*, sandbox-*, dev-*, user-named)
    #   -n / --limit N          max rows (default 30; 0 = no limit)
    #   -p / --powerplay        only powerplay branch sandboxes (br-*)
    #   -f / --fresh            bypass cache and refetch
    #   -m / --mine             only sandboxes you've lovssh'd into
    #   -b / --branch <substr>  filter by branch substring (implies --mine)
    argparse 'a/all' 'p/powerplay' 'f/fresh' 'm/mine' 'n/limit=!_validate_int' 'b/branch=' -- $argv
    or return

    set -l limit 30
    if set -q _flag_limit
        set limit $_flag_limit
    end

    # --branch implies --mine: branch info only exists in lovssh history.
    if set -q _flag_branch
        set _flag_mine 1
    end

    # Build claim->{branch, input, last_seen} map from lovssh history.
    set -l history_file $HOME/.local/state/lovssh/history.jsonl
    set -l hist_map '{}'
    if test -f $history_file
        # Prefer daphen_branch (the work-branch identifier — stable across
        # Lovable's edit/edt-* per-prompt churn) over branch (HEAD at SSH
        # time, often an ephemeral edit/edt-<uuid>).
        set hist_map (jq -s '
            group_by(.claim) | map({
                key: .[0].claim,
                value: (sort_by(.timestamp) | last | {
                    branch: (.daphen_branch // .branch // ""),
                    head: (.branch // ""),
                    input,
                    last_seen: .timestamp
                })
            }) | from_entries
        ' $history_file 2>/dev/null)
        if test -z "$hist_map"; set hist_map '{}'; end
    end

    # 60-second filesystem cache for the merged sandcastle response. Both
    # endpoints fetched in parallel on a miss.
    set -l cache_file /tmp/lovlist-cache.$USER.json
    set -l ttl 60

    set -l use_cache 0
    if not set -q _flag_fresh; and test -f $cache_file
        set -l mtime (stat -c %Y $cache_file 2>/dev/null)
        if test -n "$mtime"
            set -l age (math (date +%s) - $mtime)
            if test $age -lt $ttl
                set use_cache 1
            end
        end
    end

    set -l merged
    if test $use_cache -eq 1
        set merged (cat $cache_file)
    else
        set -l p_tmp (mktemp)
        set -l s_tmp (mktemp)
        curl -s "https://sandcastle.lovable.net/api/v1/sandboxes" > $p_tmp &
        curl -s "https://sandcastle.lovable.net/api/v1/sandboxes?access=shared" > $s_tmp &
        wait
        set merged (jq -s '([.[0][]?, .[1][]?] | unique_by(.name))' $p_tmp $s_tmp)
        rm -f $p_tmp $s_tmp
        echo $merged > $cache_file
    end

    # Build the jq filter chain.
    set -l filter '.[]'
    if set -q _flag_all
        # no name filter
    else if set -q _flag_powerplay
        set filter '.[] | select(.name | startswith("br-"))'
    else
        set filter '.[] | select(.name | test("^lovable-[0-9a-f]{16}$"))'
    end

    set -l branch_substr ''
    if set -q _flag_branch; set branch_substr $_flag_branch; end
    set -l mine_filter 'true'
    if set -q _flag_mine
        set mine_filter '($hist[.name] != null)'
    end
    set -l branch_filter 'true'
    if test -n "$branch_substr"
        set branch_filter "(($hist[.name].branch // \"\") | test(\"$branch_substr\"; \"i\"))"
    end

    set -l rows (echo $merged | jq -r --argjson hist "$hist_map" "
        [$filter | select($mine_filter and $branch_filter)] |
        sort_by(.creation_time) | reverse |
        .[] |
        [
          .name,
          .status,
          (.project_id // \"?\"),
          (\$hist[.name].branch // \"-\"),
          .creation_time
        ] |
        @tsv
    ")

    set -l n (count $rows)
    if test $n -eq 0
        echo "No matching sandboxes found."
        return 0
    end

    if test $limit -gt 0 -a $n -gt $limit
        set rows $rows[1..$limit]
        printf "%s\n" $rows | column -t -s \t -N CLAIM,STATUS,PROJECT,BRANCH,CREATED
        echo
        echo "($limit of $n shown — -n 0 = all, -a = include scratch, -m = only yours, -b SUBSTR = branch filter, -f = bypass cache)"
    else
        printf "%s\n" $rows | column -t -s \t -N CLAIM,STATUS,PROJECT,BRANCH,CREATED
    end
end
