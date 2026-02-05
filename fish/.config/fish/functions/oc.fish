function oc --description "Run opencode with Claude Max subscription (no API key)"
    set -l old_key $ANTHROPIC_API_KEY
    set -e ANTHROPIC_API_KEY
    command opencode $argv
    if test -n "$old_key"
        set -gx ANTHROPIC_API_KEY $old_key
    end
end
