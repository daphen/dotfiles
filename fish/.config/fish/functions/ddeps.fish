function ddeps --description "devenv deps with Custom Style process-compose theme + uncolored api logs"
    set -lx DEVENV_NO_LOG_COLOR 1
    if contains -- -- $argv
        devenv deps $argv
    else
        devenv deps $argv -- --theme "Custom Style"
    end
end
