function theme_system -d "Centralized theme management"
    set -l theme_manager "$HOME/.config/themes/theme-manager.sh"
    
    if not test -x "$theme_manager"
        echo "Error: Theme manager not found at $theme_manager"
        return 1
    end
    
    switch "$argv[1]"
        case "switch"
            # Switch to specific theme
            if test (count $argv) -lt 2
                echo "Usage: theme_system switch <dark|light>"
                return 1
            end
            
            # Run theme manager
            "$theme_manager" switch "$argv[2]"
            
            # Apply Fish theme immediately
            if test "$argv[2]" = "dark"
                source "$HOME/.config/themes/generated/fish/dark.theme"
                set -g THEME_MODE "dark"
            else
                source "$HOME/.config/themes/generated/fish/light.theme"
                set -g THEME_MODE "light"
            end
            
            # Apply FZF colors using existing function
            set_fzf_colors
            echo "Theme switched to $argv[2] mode"
            
        case "toggle"
            # Toggle between light and dark
            set -l current_theme (defaults read -g AppleInterfaceStyle 2>/dev/null; or echo "Light")
            if test "$current_theme" = "Dark"
                theme_system switch light
            else
                theme_system switch dark
            end
            
        case "auto"
            # Auto-detect and apply system theme
            "$theme_manager" auto
            
            # Apply Fish theme based on system setting
            set -l system_theme (defaults read -g AppleInterfaceStyle 2>/dev/null; or echo "Light")
            if test "$system_theme" = "Dark"
                source "$HOME/.config/themes/generated/fish/dark.theme"
                set -g THEME_MODE "dark"
            else
                source "$HOME/.config/themes/generated/fish/light.theme"
                set -g THEME_MODE "light"
            end
            
            # Apply FZF colors using existing function
            set_fzf_colors
            
        case "status"
            # Show current theme status
            "$theme_manager" status
            
        case "*"
            echo "Centralized Theme Management"
            echo ""
            echo "Usage: theme_system <command> [args]"
            echo ""
            echo "Commands:"
            echo "  switch <mode>   Switch to specific theme mode (dark/light)"
            echo "  toggle          Toggle between light and dark themes"
            echo "  auto            Auto-detect and apply system theme"
            echo "  status          Show current theme status"
            echo ""
            echo "Examples:"
            echo "  theme_system auto         # Auto-detect and apply system theme"
            echo "  theme_system switch dark  # Switch to dark theme"
            echo "  theme_system toggle       # Toggle between themes"
    end
end