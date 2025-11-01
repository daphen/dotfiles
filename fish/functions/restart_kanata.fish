function restart_kanata --description "Restart Kanata with dual configuration support"
    set -l kanata_dir "$HOME/.config/kanata"
    
    # Use the simple start-dual script
    if test -f "$kanata_dir/start-dual.sh"
        echo "Restarting Kanata..."
        bash "$kanata_dir/start-dual.sh"
    else
        echo "Error: Kanata script not found at $kanata_dir/start-dual.sh"
        return 1
    end
end