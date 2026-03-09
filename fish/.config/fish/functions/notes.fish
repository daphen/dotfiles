function notes --description "Notes sync and management"
    set -l notes_dir ~/personal/notes
    set -g __notes_storage_dir $notes_dir/storage
    set -g __notes_cache_file $notes_dir/.sync-cache
    set -l config_file $notes_dir/sync.conf

    # Load config
    if not test -f $config_file
        echo "Error: Config not found at $config_file"
        return 1
    end
    set -g __notes_api_url (grep "^API_URL=" $config_file | cut -d'"' -f2)
    set -g __notes_auth_password (grep "^AUTH_PASSWORD=" $config_file | cut -d'"' -f2)

    # Helper: get auth token
    function __notes_get_token
        curl -s -X POST "$__notes_api_url/api/auth" \
            -H "Content-Type: application/json" \
            -d "{\"password\": \"$__notes_auth_password\"}" \
            -c - 2>/dev/null | grep notes-auth | awk '{print $7}'
    end

    # Helper: pull from server
    function __notes_pull --argument token
        echo "⬇ Pulling from server..."
        set -l response (curl -s "$__notes_api_url/api/sync" -H "Cookie: notes-auth=$token")

        # Get list of server paths
        set -l server_paths (echo $response | jq -r '.changes[]?.path // empty')

        # Update/create notes from server
        echo $response | jq -r '.changes[]? | "\(.path)\t\(.content)"' | while read -l line
            set -l path (echo $line | cut -f1)
            set -l content (echo $line | cut -f2-)
            if test -n "$path" -a -n "$content"
                set -l filepath $__notes_storage_dir/$path
                mkdir -p (dirname $filepath)
                echo $content > $filepath
                echo "  ✓ $path"
            end
        end

        # Delete local files not on server
        for file in (find $__notes_storage_dir -name "*.md" -type f 2>/dev/null)
            set -l relative_path (string replace "$__notes_storage_dir/" "" $file)
            if not contains $relative_path $server_paths
                rm $file
                # Remove from cache
                grep -v "^$relative_path " $__notes_cache_file 2>/dev/null > $__notes_cache_file.tmp
                mv $__notes_cache_file.tmp $__notes_cache_file 2>/dev/null
                echo "  ✗ deleted $relative_path"
            end
        end
    end

    # Helper: push to server (only changed files)
    function __notes_push --argument token
        set -l pushed 0
        # Use find to avoid glob duplicates
        for file in (find $__notes_storage_dir -name "*.md" -type f 2>/dev/null)
            set -l relative_path (string replace "$__notes_storage_dir/" "" $file)
            set -l current_hash (md5sum $file | cut -d' ' -f1)
            set -l cached_hash (grep "^$relative_path " $__notes_cache_file 2>/dev/null | cut -d' ' -f2)

            # Skip if unchanged
            if test "$current_hash" = "$cached_hash"
                continue
            end

            set -l content_json (cat $file | jq -Rs .)
            set -l result (curl -s -X POST "$__notes_api_url/api/sync" \
                -H "Content-Type: application/json" \
                -H "Cookie: notes-auth=$token" \
                -d "{
                    \"clientId\": \"linux-cli\",
                    \"changes\": [{
                        \"path\": \"$relative_path\",
                        \"content\": $content_json,
                        \"action\": \"update\"
                    }]
                }" | jq -r 'if .accepted | length > 0 then "ok" else "fail" end')

            if test "$result" = "ok"
                echo "  ✓ $relative_path"
                # Update cache
                grep -v "^$relative_path " $__notes_cache_file 2>/dev/null > $__notes_cache_file.tmp
                echo "$relative_path $current_hash" >> $__notes_cache_file.tmp
                mv $__notes_cache_file.tmp $__notes_cache_file
                set pushed (math $pushed + 1)
            else
                echo "  ✗ $relative_path"
            end
        end
        if test $pushed -eq 0
            echo "  No changes to push"
        end
    end

    switch $argv[1]
        case sync
            set -l token (__notes_get_token)
            if test -z "$token"
                echo "Failed to authenticate"
                return 1
            end
            __notes_pull $token
            __notes_push $token
            echo "✓ Sync complete"

        case push
            set -l token (__notes_get_token)
            if test -z "$token"
                echo "Failed to authenticate"
                return 1
            end
            __notes_push $token

        case pull
            set -l token (__notes_get_token)
            if test -z "$token"
                echo "Failed to authenticate"
                return 1
            end
            __notes_pull $token

        case new
            set -l filename $argv[2]
            if test -z "$filename"
                echo "Usage: notes new <filename>"
                return 1
            end

            if not string match -q "*.md" $filename
                set filename "$filename.md"
            end

            set -l filepath $__notes_storage_dir/$filename
            mkdir -p (dirname $filepath)
            touch $filepath
            nvim $filepath
            # Auto-sync after editing
            notes push

        case edit e
            set -l filename $argv[2]
            if test -z "$filename"
                # Use fzf with Ctrl-D to delete
                while true
                    set -l selected (find $__notes_storage_dir -name "*.md" -type f 2>/dev/null | sed "s|$__notes_storage_dir/||" | fzf --preview "cat $__notes_storage_dir/{}" --bind "ctrl-d:execute(rm $__notes_storage_dir/{} && echo 'Deleted {}')+reload(find $__notes_storage_dir -name '*.md' -type f 2>/dev/null | sed 's|$__notes_storage_dir/||')" --header "Enter: edit | Ctrl-D: delete")
                    if test -z "$selected"
                        break
                    end
                    nvim $__notes_storage_dir/$selected
                    # Auto-sync after editing
                    notes push
                end
            else
                if not string match -q "*.md" $filename
                    set filename "$filename.md"
                end
                nvim $__notes_storage_dir/$filename
                # Auto-sync after editing
                notes push
            end

        case ls list
            find $__notes_storage_dir -name "*.md" -type f 2>/dev/null | sed "s|$__notes_storage_dir/||" | sort

        case delete rm
            set -l filename $argv[2]
            if test -z "$filename"
                set -l selected (find $__notes_storage_dir -name "*.md" -type f 2>/dev/null | sed "s|$__notes_storage_dir/||" | fzf --preview "cat $__notes_storage_dir/{}" --header "Select note to delete")
                if test -n "$selected"
                    rm $__notes_storage_dir/$selected
                    echo "✗ Deleted $selected"
                    notes push
                end
            else
                if not string match -q "*.md" $filename
                    set filename "$filename.md"
                end
                if test -f $__notes_storage_dir/$filename
                    rm $__notes_storage_dir/$filename
                    echo "✗ Deleted $filename"
                    notes push
                else
                    echo "Note not found: $filename"
                    return 1
                end
            end

        case open
            xdg-open $__notes_api_url

        case ''
            echo "Usage: notes <command>"
            echo ""
            echo "Commands:"
            echo "  sync          - Pull then push (full sync)"
            echo "  push          - Push local notes to server"
            echo "  pull          - Pull notes from server"
            echo "  new <name>    - Create new note, open in nvim"
            echo "  edit [name]   - Edit note (fzf if no name, Ctrl-D to delete)"
            echo "  delete [name] - Delete note (fzf if no name)"
            echo "  ls            - List local notes"
            echo "  open          - Open web app"

        case '*'
            echo "Unknown command: $argv[1]"
            return 1
    end

    # Cleanup helper functions and global vars
    functions -e __notes_get_token __notes_pull __notes_push
    set -e __notes_api_url __notes_auth_password __notes_storage_dir __notes_cache_file
end
