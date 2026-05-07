function dwt --description "devenv wt with Custom Style process-compose theme + uncolored api logs"
    set -lx DEVENV_NO_LOG_COLOR 1
    if contains -- -- $argv
        devenv wt $argv
    else
        devenv wt $argv -- --theme "Custom Style"
    end
end
