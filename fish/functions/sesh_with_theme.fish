function sesh_with_theme --description "Launch sesh with current FZF theme"
    # Source the current theme's FZF colors
    if test "$THEME_MODE" = "light"
        if test -f ~/.config/themes/generated/fzf/light.theme
            source ~/.config/themes/generated/fzf/light.theme
        end
    else
        if test -f ~/.config/themes/generated/fzf/dark.theme
            source ~/.config/themes/generated/fzf/dark.theme
        end
    end
    
    # Update tmux environment
    if test -n "$TMUX"
        tmux setenv FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS"
    end
    
    # Now run the sesh command with the updated environment
    sesh $argv
end