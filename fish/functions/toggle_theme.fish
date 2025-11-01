function toggle_theme -d "Toggle between light and dark themes"
    # Get current system theme
    set -l current_system_theme (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
    
    # Toggle the actual macOS system theme
    if test "$current_system_theme" = "Dark"
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
        # Use the set_light_theme function which handles everything
        set_light_theme
    else
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
        # Use the set_dark_theme function which handles everything
        set_dark_theme
    end
    
    # Sync OpenCode theme
    sync_opencode_theme
end
