function theme_logger --description "Centralized logging for theme switching"
    set -l log_file ~/.config/theme-switch.log
    set -l timestamp (date '+%Y-%m-%d %H:%M:%S')
    
    # Create log directory if it doesn't exist
    mkdir -p (dirname $log_file)
    
    # Log the message with timestamp
    echo "[$timestamp] $argv" >> $log_file
    
    # Also output to console with color
    set_color green
    echo "🎨 [$timestamp] $argv"
    set_color normal
end