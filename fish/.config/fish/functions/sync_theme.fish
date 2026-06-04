function sync_theme --description "Sync themes with current theme setting"
    # Get current theme (default to dark)
    set -l current_theme "dark"
    if test -f ~/.config/theme_mode
        set current_theme (cat ~/.config/theme_mode)
    end

    # Update Fish theme for current session
    if test "$current_theme" = "dark"
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
end