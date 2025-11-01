function set_dark_theme --description "Set dark theme"
    # Store current theme mode
    set -g THEME_MODE "dark"

    # Load colors from generated theme file
    set -l theme_file ~/.config/themes/generated/fish/dark.theme
    if test -f $theme_file
        source $theme_file
    else
        # Fallback to hardcoded colors if theme file doesn't exist
        set -g fish_color_normal CCD5E5
        set -g fish_color_command 6A8BE3
        set -g fish_color_keyword A9B9EF
        set -g fish_color_quote 74BAA8
        set -g fish_color_redirection BCB6EC
        set -g fish_color_end b09884
        set -g fish_color_error F71735
        set -g fish_color_param CCD5E5
        set -g fish_color_comment 474B65
        set -g fish_color_selection --background=121E42
        set -g fish_color_search_match --background=121E42
        set -g fish_color_operator b09884
        set -g fish_color_escape BCB6EC
        set -g fish_color_autosuggestion 474B65

        # Set pager colors
        set -g fish_pager_color_progress 474B65
        set -g fish_pager_color_prefix b09884
        set -g fish_pager_color_completion CCD5E5
        set -g fish_pager_color_description 474B65
        set -g fish_pager_color_selected_background --background=121E42
    end

    # Update FZF colors
    set_fzf_colors

    # Update Tide prompt colors
    set -l tide_theme_file ~/.config/themes/generated/tide/dark.theme
    if test -f $tide_theme_file
        # Execute each line to ensure universal variables are updated
        for line in (cat $tide_theme_file | grep "^set -U")
            eval $line
        end
    end

    # Refresh tmux if running
    if tmux info &> /dev/null
        tmux source-file ~/.config/tmux/tmux.conf >/dev/null 2>&1
    end

    echo "🌙 Switched to dark theme"
    
    # Force Tide to reload with new colors
    # Clear tide prompt cache to force regeneration
    set -e _tide_prompt_cache
    set -e _tide_right_prompt_cache
    
    # If tide reload exists, use it
    if type -q tide
        tide reload >/dev/null 2>&1 || true
    end
    
    # Force prompt redraw
    commandline -f repaint
end


    # Sync OpenCode theme
    sync_opencode_theme
