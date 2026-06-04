# Theme watcher - automatically refresh Tide prompt when theme changes
# Works with the theme-generator system

set -g __theme_watcher_last_mode ""

function __theme_watcher_check --on-event fish_prompt
    set -l theme_file "$HOME/.config/theme_mode"
    set -l themes_dir "$HOME/.config/themes/generated"

    if test -f $theme_file
        set -l current_mode (cat $theme_file)

        # Only update if theme mode changed
        if test "$current_mode" != "$__theme_watcher_last_mode"
            set -g __theme_watcher_last_mode $current_mode

            # Note: Tide always uses dark theme (looks good in both modes)

            # Source the fish theme
            set -l fish_theme "$themes_dir/fish/$current_mode.theme"
            if test -f $fish_theme
                source $fish_theme
            end
        end
    end
end

# Always use dark Tide theme (looks good in both light and dark modes)
set -l tide_dark_theme "$HOME/.config/themes/generated/tide/dark.theme"
if test -f $tide_dark_theme
    source $tide_dark_theme
end

# Initialize on shell start
__theme_watcher_check
