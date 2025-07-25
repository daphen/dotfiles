function theme_log --description "View theme switching logs"
    set -l log_file ~/.config/theme-switch.log
    
    # Check if log file exists
    if not test -f $log_file
        echo "📋 No theme switching logs found yet"
        echo "💡 Switch themes to start logging activity"
        return 1
    end
    
    if count $argv > /dev/null
        switch $argv[1]
            case "tail" "-f" "--follow"
                echo "📋 Following theme switching logs (Ctrl+C to stop)..."
                tail -f $log_file
            case "clear" "--clear"
                echo "🧹 Clearing theme switching logs..."
                echo "" > $log_file
                echo "✅ Theme logs cleared"
            case "last" "-l"
                echo "📋 Last 10 theme switching events:"
                tail -n 10 $log_file
            case "*"
                echo "📋 Theme switching logs:"
                cat $log_file
        end
    else
        echo "📋 Theme switching logs:"
        cat $log_file
    end
end