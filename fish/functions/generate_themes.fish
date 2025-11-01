function generate_themes --description "Generate both light and dark themes"
    ~/.config/themes/generate-themes.sh
    
    # Reload current theme to apply Tide changes
    set current_theme (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
    if test "$current_theme" = "Dark"
        set_dark_theme
    else
        set_light_theme
    end
    
    echo "🔄 Theme settings reloaded"
end