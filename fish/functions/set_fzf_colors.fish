function set_fzf_colors --description "Set FZF colors based on current theme"
    if test "$THEME_MODE" = "light"
        # Source light theme FZF colors from generated file
        if test -f ~/.config/themes/generated/fzf/light.theme
            source ~/.config/themes/generated/fzf/light.theme
        end
    else
        # Source dark theme FZF colors from generated file
        if test -f ~/.config/themes/generated/fzf/dark.theme
            source ~/.config/themes/generated/fzf/dark.theme
        end
    end
    
    # Update tmux environment
    if tmux info &> /dev/null
        # Set global environment for new panes/windows
        tmux setenv -g FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS"
        
        # Also update the current session's environment
        if test -n "$TMUX"
            tmux setenv FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS"
        end
    end
end
