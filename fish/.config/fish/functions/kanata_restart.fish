function kanata_restart --description "Restart Kanata (excludes Piantor via device exclusion)"
    set -l kanata_dir "$HOME/.config/kanata"

    # Use the restart script
    if test -f "$kanata_dir/restart-kanata.sh"
        echo "Restarting Kanata..."
        bash "$kanata_dir/restart-kanata.sh"
    else
        echo "Error: Kanata script not found at $kanata_dir/restart-kanata.sh"
        return 1
    end
end