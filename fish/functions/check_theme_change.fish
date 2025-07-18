function check_theme_change --description "Check if theme was changed externally and sync"
    set -l marker_file "$HOME/.config/fish/.theme_changed"
    
    if test -f $marker_file
        # Remove the marker file
        rm -f $marker_file 2>/dev/null
        
        # Sync the theme without spawning a new process
        sync_theme
    end
end