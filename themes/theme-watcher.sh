#!/bin/bash

# Theme Watcher - Automatically sync themes with system appearance changes
# This script monitors macOS system appearance changes and triggers theme updates

THEMES_DIR="$HOME/.config/themes"
THEME_MANAGER="$THEMES_DIR/theme-manager.sh"
LOCK_FILE="/tmp/theme-watcher.lock"
LOG_FILE="$HOME/.config/themes/theme-watcher.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    log_message "INFO: $1"
}

log_success() {
    log_message "SUCCESS: $1"
}

log_error() {
    log_message "ERROR: $1"
}

# Check if another instance is running
check_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_error "Another instance is already running (PID: $pid)"
            exit 1
        else
            log_info "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
}

# Create lock file
create_lock() {
    echo $$ > "$LOCK_FILE"
    trap cleanup EXIT
}

# Cleanup on exit
cleanup() {
    rm -f "$LOCK_FILE"
    log_info "Theme watcher stopped"
}

# Get current system appearance
get_system_appearance() {
    defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"
}

# Get theme mode from appearance
get_theme_mode() {
    local appearance=$(get_system_appearance)
    if [[ "$appearance" == "Dark" ]]; then
        echo "dark"
    else
        echo "light"
    fi
}

# Apply theme using centralized manager
apply_theme() {
    local theme_mode=$1
    log_info "Applying $theme_mode theme..."
    
    if [[ -x "$THEME_MANAGER" ]]; then
        "$THEME_MANAGER" switch "$theme_mode" >> "$LOG_FILE" 2>&1
        if [[ $? -eq 0 ]]; then
            log_success "Theme switched to $theme_mode"
            
            # Fish shells will pick up theme changes via the check_theme_change function
            # which runs on each prompt, so we don't need to send signals
            
            # Notify Neovim instances (if any) to reload colorscheme
            # This uses nvim --server if available, otherwise just logs
            if command -v nvim >/dev/null 2>&1; then
                for nvim_socket in /tmp/nvim*/0; do
                    if [[ -S "$nvim_socket" ]]; then
                        nvim --server "$nvim_socket" --remote-send ":ReloadColors<CR>" 2>/dev/null || true
                    fi
                done
            fi
            
        else
            log_error "Failed to switch theme to $theme_mode"
        fi
    else
        log_error "Theme manager not found or not executable: $THEME_MANAGER"
    fi
}

# Main monitoring loop
monitor_theme_changes() {
    local current_theme=$(get_theme_mode)
    log_info "Starting theme monitoring - initial theme: $current_theme"
    
    # Apply initial theme
    apply_theme "$current_theme"
    
    # Monitor system preferences for changes
    if command -v fswatch >/dev/null 2>&1; then
        log_info "Using fswatch for monitoring system preferences"
        
        # Monitor the global preferences file that contains appearance settings
        fswatch -o "$HOME/Library/Preferences/.GlobalPreferences.plist" 2>/dev/null | while read -r event; do
            # Small delay to ensure the preference change is fully written
            sleep 0.5
            
            local new_theme=$(get_theme_mode)
            if [[ "$new_theme" != "$current_theme" ]]; then
                log_info "System appearance changed from $current_theme to $new_theme"
                current_theme=$new_theme
                apply_theme "$current_theme"
            fi
        done
    else
        log_info "fswatch not available, using periodic checking (install with: brew install fswatch)"
        
        # Fallback: poll every 2 seconds
        while true; do
            sleep 2
            local new_theme=$(get_theme_mode)
            if [[ "$new_theme" != "$current_theme" ]]; then
                log_info "System appearance changed from $current_theme to $new_theme"
                current_theme=$new_theme
                apply_theme "$current_theme"
            fi
        done
    fi
}

# Show help
show_help() {
    cat << EOF
Theme Watcher - Automatic system theme synchronization

Usage: $0 [COMMAND]

Commands:
    start       Start monitoring system theme changes (default)
    stop        Stop the theme watcher
    status      Show current status
    test        Test theme switching once
    help        Show this help message

The theme watcher automatically monitors macOS system appearance changes
and triggers the centralized theme manager to update all configured tools.

Log file: $LOG_FILE
Lock file: $LOCK_FILE
EOF
}

# Stop existing watcher
stop_watcher() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid"
            log_info "Stopped theme watcher (PID: $pid)"
        else
            log_info "No running theme watcher found"
            rm -f "$LOCK_FILE"
        fi
    else
        log_info "No lock file found - theme watcher is not running"
    fi
}

# Show status
show_status() {
    local current_theme=$(get_theme_mode)
    local system_appearance=$(get_system_appearance)
    
    echo "=== Theme Watcher Status ==="
    echo "System Appearance: $system_appearance"
    echo "Current Theme Mode: $current_theme"
    echo "Log file: $LOG_FILE"
    
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Status: Running (PID: $pid)"
        else
            echo "Status: Not running (stale lock file)"
        fi
    else
        echo "Status: Not running"
    fi
}

# Test theme switching
test_theme() {
    local current_theme=$(get_theme_mode)
    log_info "Testing theme switching - current theme: $current_theme"
    apply_theme "$current_theme"
}

# Main script logic
main() {
    case "${1:-start}" in
        "start")
            check_lock
            create_lock
            monitor_theme_changes
            ;;
        "stop")
            stop_watcher
            ;;
        "status")
            show_status
            ;;
        "test")
            test_theme
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"