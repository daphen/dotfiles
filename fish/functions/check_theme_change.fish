function check_theme_change --description "Check if theme was changed externally and sync"
    set -l theme_file ~/.config/themes/.current-theme
    
    if test -f $theme_file
        set -l file_theme (cat $theme_file | string trim)
        
        # Check if theme has changed
        if test "$file_theme" != "$THEME_MODE"
            # Apply the new theme
            if test "$file_theme" = "light"
                set_light_theme
            else if test "$file_theme" = "dark"
                set_dark_theme
            end
        end
    end
end