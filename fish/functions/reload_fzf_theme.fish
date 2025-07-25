function reload_fzf_theme --description "Reload FZF theme in current session"
    # Get current theme mode
    set -l theme_mode (get_current_theme_mode)
    if test -z "$theme_mode"
        set theme_mode "dark"  # fallback
    end
    
    # Load the generated FZF theme file
    set -l fzf_theme_file "$HOME/.config/themes/generated/fzf/$theme_mode.theme"
    
    if test -f "$fzf_theme_file"
        # Source the theme file to get FZF_DEFAULT_OPTS
        source "$fzf_theme_file" 2>/dev/null
        
        # Only log if we're in an interactive session and theme_logger exists
        if status is-interactive; and functions -q theme_logger
            theme_logger "✅ FZF: Reloaded $theme_mode theme in tmux session"
        end
    else
        # Only log errors in interactive sessions
        if status is-interactive; and functions -q theme_logger
            theme_logger "⚠️  FZF: Theme file not found: $fzf_theme_file"
        end
    end
end

function get_current_theme_mode --description "Get current theme mode from system"
    if test (uname) = "Darwin"
        set -l appearance (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
        if test "$appearance" = "Dark"
            echo "dark"
        else
            echo "light"
        end
    else
        echo "light"  # fallback
    end
end