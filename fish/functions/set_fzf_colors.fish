
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
end
