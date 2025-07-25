#!/bin/bash

# Theme Manager - Centralized theme management for dotfiles
# Author: Generated for custom theme system

set -e

THEMES_DIR="$HOME/.config/themes"
COLORS_FILE="$THEMES_DIR/colors.json"
TEMPLATES_DIR="$THEMES_DIR/templates"
GENERATED_DIR="$THEMES_DIR/generated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
}

# Get system appearance (macOS)
get_system_appearance() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"
    else
        echo "Light"  # Default fallback
    fi
}

# Get current theme mode
get_current_theme() {
    local appearance=$(get_system_appearance)
    if [[ "$appearance" == "Dark" ]]; then
        echo "dark"
    else
        echo "light"
    fi
}

# Extract color from JSON
get_color() {
    local theme=$1
    local path=$2
    jq -r ".themes.${theme}.${path}" "$COLORS_FILE"
}

# Generate theme for a specific tool
generate_tool_theme() {
    local tool=$1
    local theme_mode=$2
    
    # Try theme-specific template first, then fall back to generic
    local template_file="$TEMPLATES_DIR/${tool}-${theme_mode}.template"
    if [[ ! -f "$template_file" ]]; then
        template_file="$TEMPLATES_DIR/${tool}.template"
    fi
    
    local output_dir="$GENERATED_DIR/${tool}"
    
    if [[ ! -f "$template_file" ]]; then
        log_warning "Template for $tool not found: $template_file"
        return 1
    fi
    
    log_info "Generating $tool theme for $theme_mode mode..."
    
    # Create output directory and generate theme
    mkdir -p "$output_dir"
    local output_file="$output_dir/${theme_mode}.theme"
    python3 "$THEMES_DIR/theme-processor.py" "$template_file" "$COLORS_FILE" "$theme_mode" "$output_file"
    
    log_success "Generated $tool theme: $output_file"
}

# Generate all themes
generate_all() {
    local theme_mode=${1:-$(get_current_theme)}
    
    log_info "Generating all themes for $theme_mode mode..."
    
    # Generate themes for all available templates
    for template in "$TEMPLATES_DIR"/*.template; do
        if [[ -f "$template" ]]; then
            local tool=$(basename "$template" .template)
            generate_tool_theme "$tool" "$theme_mode"
        fi
    done
    
    log_success "All themes generated for $theme_mode mode"
}

# Apply theme for a specific tool
apply_tool_theme() {
    local tool=$1
    local theme_mode=$2
    local generated_file="$GENERATED_DIR/${tool}/${theme_mode}.theme"
    
    if [[ ! -f "$generated_file" ]]; then
        log_error "Generated theme file not found: $generated_file"
        return 1
    fi
    
    case "$tool" in
        "nvim")
            # Copy generated palette to colorscheme directory
            cp "$generated_file" "$HOME/.config/colorscheme/lua/rose-pine/palette.lua"
            log_success "Applied Neovim theme"
            ;;
        "nvim-custom")
            # Copy generated colors to custom theme directory
            cp "$generated_file" "$HOME/.config/nvim/lua/theme/colors.lua"
            log_success "Applied custom Neovim theme"
            ;;
        "fish")
            # Fish themes are applied by Fish itself, not by bash
            # Just log success since Fish will source it when needed
            log_success "Fish theme generated (will be applied by Fish shells)"
            ;;
        "ghostty")
            # Copy generated theme to ghostty themes directory
            cp "$generated_file" "$HOME/.config/ghostty/themes/$theme_mode"
            log_success "Generated and copied Ghostty theme"
            # Note: Ghostty auto-detects system theme changes via 'theme = light:light,dark:dark'
            # so we don't need to trigger a reload
            ;;
        "tmux")
            # Apply tmux theme (may require tmux reload)
            if tmux list-sessions &> /dev/null; then
                tmux source-file "$generated_file"
                log_success "Applied Tmux theme"
            else
                log_warning "Tmux not running, theme will apply on next start"
            fi
            ;;
        "fzf")
            # FZF themes are applied by Fish shell, not by bash
            # Just log success since Fish will source it when needed
            log_success "FZF theme generated (will be applied by Fish shells)"
            ;;
        *)
            log_warning "Unknown tool: $tool"
            return 1
            ;;
    esac
}

# Apply all themes
apply_all() {
    local theme_mode=${1:-$(get_current_theme)}
    
    log_info "Applying all themes for $theme_mode mode..."
    
    for tool_dir in "$GENERATED_DIR"/*; do
        if [[ -d "$tool_dir" ]]; then
            local tool=$(basename "$tool_dir")
            apply_tool_theme "$tool" "$theme_mode"
        fi
    done
    
    log_success "All themes applied for $theme_mode mode"
}

# Switch theme mode
switch_theme() {
    local theme_mode=$1
    
    if [[ "$theme_mode" != "dark" && "$theme_mode" != "light" ]]; then
        log_error "Invalid theme mode: $theme_mode. Use 'dark' or 'light'"
        return 1
    fi
    
    log_info "Switching to $theme_mode theme..."
    
    # Generate and apply all themes
    generate_all "$theme_mode"
    apply_all "$theme_mode"
    
    log_success "Theme switched to $theme_mode mode"
}

# Toggle between light and dark
toggle_theme() {
    local current_theme=$(get_current_theme)
    if [[ "$current_theme" == "dark" ]]; then
        switch_theme "light"
    else
        switch_theme "dark"
    fi
}

# Auto-detect and apply system theme
auto_theme() {
    local system_theme=$(get_current_theme)
    log_info "Auto-detecting system theme: $system_theme"
    switch_theme "$system_theme"
}

# Show current theme status
status() {
    local current_theme=$(get_current_theme)
    local system_appearance=$(get_system_appearance)
    
    echo "=== Theme Status ==="
    echo "System Appearance: $system_appearance"
    echo "Current Theme: $current_theme"
    echo "Themes Directory: $THEMES_DIR"
    echo "Colors File: $COLORS_FILE"
    echo ""
    echo "Available Tools:"
    for template in "$TEMPLATES_DIR"/*.template; do
        if [[ -f "$template" ]]; then
            local tool=$(basename "$template" .template)
            echo "  - $tool"
        fi
    done
}

# Show help
show_help() {
    cat << EOF
Theme Manager - Centralized theme management for dotfiles

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    generate [MODE]     Generate themes for specified mode (dark/light)
    apply [MODE]        Apply themes for specified mode (dark/light)
    switch [MODE]       Switch to specified theme mode (dark/light)
    toggle              Toggle between light and dark themes
    auto                Auto-detect and apply system theme
    status              Show current theme status
    help                Show this help message

Options:
    MODE                Theme mode: 'dark' or 'light' (auto-detected if not specified)

Examples:
    $0 auto             # Auto-detect and apply system theme
    $0 switch dark      # Switch to dark theme
    $0 toggle           # Toggle between light and dark
    $0 generate light   # Generate light theme files only
    $0 status           # Show current status

EOF
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-}" in
        "generate")
            generate_all "$2"
            ;;
        "apply")
            apply_all "$2"
            ;;
        "switch")
            switch_theme "$2"
            ;;
        "toggle")
            toggle_theme
            ;;
        "auto")
            auto_theme
            ;;
        "status")
            status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            auto_theme
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"