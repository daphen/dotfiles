function debug_theme -d "Debug theme and FZF settings"
    echo "=== Theme Debug ==="
    echo "THEME_MODE: $THEME_MODE"
    echo "FZF_DEFAULT_OPTS set: " (test -n "$FZF_DEFAULT_OPTS"; and echo "YES" || echo "NO")
    if test -n "$FZF_DEFAULT_OPTS"
        echo "FZF colors (first 60 chars): " (echo $FZF_DEFAULT_OPTS | string sub -l 60)
    end
    echo "FZF binary: " (which fzf)
    echo "System theme: " (defaults read -g AppleInterfaceStyle 2>/dev/null; or echo "Light")
    echo "Fish config sourced: " (test -f ~/.config/fish/config.fish; and echo "YES" || echo "NO")
    
    # Test FZF with explicit colors
    echo ""
    echo "Testing FZF with current colors:"
    echo "a\nb\nc" | fzf --height=3 --no-sort --print-query --preview="echo 'Test: {}'" || echo "FZF test done"
end