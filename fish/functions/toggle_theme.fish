function toggle_theme -d "Toggle between light and dark themes"
    # Get current system theme
    set -l current_system_theme (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
    
    # Toggle the actual macOS system theme
    if test "$current_system_theme" = "Dark"
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
        set -l new_theme "light"
        echo "🌞 Switched to light mode"
    else
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
        set -l new_theme "dark"
        echo "🌙 Switched to dark mode"
    end
    
    # Update Fish theme for current session (theme files should already exist)
    if test -f ~/.config/themes/generated/fish/$new_theme.theme
        source ~/.config/themes/generated/fish/$new_theme.theme
        set -g THEME_MODE "$new_theme"
    end
    
    # Update FZF colors
    set_fzf_colors
    
    # Update tmux environment with new FZF colors for all sessions
    if command -v tmux >/dev/null 2>&1
        for session in (tmux list-sessions -F '#S' 2>/dev/null || true)
            tmux setenv -t "$session" FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS" 2>/dev/null || true
        end
        tmux setenv -g FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS" 2>/dev/null || true
    end
end