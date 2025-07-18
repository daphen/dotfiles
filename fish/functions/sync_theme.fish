function sync_theme --description "Sync themes with current system theme (no system toggle)"
    # Get current system theme
    set -l system_theme (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
    
    # Update Fish theme for current session
    if test "$system_theme" = "Dark"
        if test -f ~/.config/themes/generated/fish/dark.theme
            source ~/.config/themes/generated/fish/dark.theme
            set -g THEME_MODE "dark"
        end
    else
        if test -f ~/.config/themes/generated/fish/light.theme
            source ~/.config/themes/generated/fish/light.theme
            set -g THEME_MODE "light"
        end
    end
    
    # Update FZF colors
    set_fzf_colors
    
    # Update tmux environment with new FZF colors
    if test -n "$TMUX"
        tmux setenv -g FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS"
    end
end