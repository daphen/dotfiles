function eww_restart --description "Restart eww daemon and open all windows"
    set -l eww_dir "$HOME/.config/eww"

    if test -f "$eww_dir/start-eww.sh"
        echo "Restarting eww..."
        bash "$eww_dir/start-eww.sh"
    else
        echo "Error: eww script not found at $eww_dir/start-eww.sh"
        return 1
    end
end
