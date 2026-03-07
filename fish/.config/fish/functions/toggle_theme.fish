function toggle_theme -d "Toggle between light and dark themes"
    # Use the centralized theme manager to toggle all apps
    bash ~/.config/themes/theme-manager.sh toggle
    
    # Source the new fish theme in this shell
    set -l new_theme (cat ~/.config/theme_mode)
    if test -f ~/.config/themes/generated/fish/$new_theme.theme
        source ~/.config/themes/generated/fish/$new_theme.theme
    end
    if test -f ~/.config/themes/generated/tide/$new_theme.theme
        source ~/.config/themes/generated/tide/$new_theme.theme
    end
end