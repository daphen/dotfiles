function claude --description "Launch Claude Code, with ai-tracker dev channel when actually configured"
    # The --dangerously-load-development-channels flag only makes sense
    # when an mcpServers entry named `ai-tracker` exists in ~/.claude.json.
    # On proart it does (stdio MCP at ~/dotfiles/.../channel.ts); in
    # lovbox sandboxes it doesn't (that path doesn't exist), and passing
    # the flag there causes the CLI to parse subsequent args as untagged
    # channel values AND suppress the regular mcpServers loading.
    if test -f $HOME/.claude.json; and grep -q '"ai-tracker"' $HOME/.claude.json 2>/dev/null
        command claude --dangerously-load-development-channels server:ai-tracker $argv
    else
        command claude $argv
    end
end
