#!/bin/bash

# Theme Manager - Centralized theme management for dotfiles
# https://github.com/daphen/theme-generator

set -e

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

THEMES_DIR="$SCRIPT_DIR"
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

# Theme mode file
THEME_MODE_FILE="$HOME/.config/theme_mode"

# Get current theme mode from file
get_current_theme() {
    if [[ -f "$THEME_MODE_FILE" ]]; then
        cat "$THEME_MODE_FILE"
    else
        echo "dark"  # Default fallback
    fi
}

# Set theme mode to file
set_theme_mode() {
    local mode=$1
    echo "$mode" > "$THEME_MODE_FILE"
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

    # Collect unique tool names (handling mode-specific templates like nvim-dark, nvim-light)
    local -A tools_seen
    for template in "$TEMPLATES_DIR"/*.template; do
        if [[ -f "$template" ]]; then
            local tool=$(basename "$template" .template)
            # Extract base tool name (nvim-dark -> nvim, nvim-light -> nvim)
            local base_tool="${tool%-dark}"
            base_tool="${base_tool%-light}"
            tools_seen["$base_tool"]=1
        fi
    done

    # Generate themes for each unique tool
    for tool in "${!tools_seen[@]}"; do
        generate_tool_theme "$tool" "$theme_mode"
    done

    log_success "All themes generated for $theme_mode mode"
}

# Apply theme for a specific tool
apply_tool_theme() {
    local tool=$1
    local theme_mode=$2
    local generated_file="$GENERATED_DIR/${tool}/${theme_mode}.theme"

    # Some tools don't need a generated file (they update config directly)
    local no_generated_file_needed=("rofi")
    local needs_file=true
    for skip_tool in "${no_generated_file_needed[@]}"; do
        if [[ "$tool" == "$skip_tool" ]]; then
            needs_file=false
            break
        fi
    done

    if [[ "$needs_file" == true && ! -f "$generated_file" ]]; then
        log_error "Generated theme file not found: $generated_file"
        return 1
    fi

    case "$tool" in
        "nvim")
            if [[ -d "$HOME/.config/nvim" ]]; then
                mkdir -p "$HOME/.config/nvim/colors"
                cp "$generated_file" "$HOME/.config/nvim/colors/custom-theme-${theme_mode}.lua"
                log_success "Applied Neovim ${theme_mode} theme"
            fi
            ;;
        "mako")
            if [[ -d "$HOME/.config/mako" ]] || command -v mako &> /dev/null; then
                mkdir -p "$HOME/.config/mako"
                cp "$generated_file" "$HOME/.config/mako/config"
                if pgrep -x mako > /dev/null; then
                    makoctl reload
                    log_success "Applied and reloaded Mako theme"
                else
                    log_success "Applied Mako theme (not running)"
                fi
            fi
            ;;
        "waybar")
            if [[ -d "$HOME/.config/waybar" ]] || command -v waybar &> /dev/null; then
                mkdir -p "$HOME/.config/waybar"
                cp "$generated_file" "$HOME/.config/waybar/style.css"
                if pgrep -x waybar > /dev/null; then
                    killall -SIGUSR2 waybar
                    log_success "Applied and reloaded Waybar theme"
                else
                    log_success "Applied Waybar theme (not running)"
                fi
            fi
            ;;
        "fish")
            if command -v fish &> /dev/null; then
                log_success "Fish theme generated (will be applied by Fish shells)"
            fi
            ;;
        "ghostty")
            if [[ -d "$HOME/.config/ghostty" ]] || command -v ghostty &> /dev/null; then
                mkdir -p "$HOME/.config/ghostty/themes"
                cp "$generated_file" "$HOME/.config/ghostty/themes/$theme_mode"
                log_success "Generated and copied Ghostty theme"
            fi
            ;;
        "tmux")
            if command -v tmux &> /dev/null; then
                if tmux list-sessions &> /dev/null; then
                    tmux source-file "$generated_file"
                    log_success "Applied Tmux theme"
                else
                    log_success "Tmux theme generated (will apply on next start)"
                fi
            fi
            ;;
        "fzf")
            if command -v fzf &> /dev/null; then
                log_success "FZF theme generated (will be applied by Fish shells)"
            fi
            ;;
        "tide")
            if command -v fish &> /dev/null; then
                fish -c "source '$generated_file'"
                log_success "Applied Tide prompt theme"
            fi
            ;;
        "wezterm")
            if [[ -d "$HOME/.config/wezterm" ]] || command -v wezterm &> /dev/null; then
                mkdir -p "$HOME/.config/wezterm/colors"
                cp "$generated_file" "$HOME/.config/wezterm/colors/${theme_mode}.lua"
                log_success "Applied Wezterm ${theme_mode} theme"
            fi
            ;;
        "spotify-player")
            if [[ -d "$HOME/.config/spotify-player" ]] || command -v spotify_player &> /dev/null; then
                mkdir -p "$HOME/.config/spotify-player"
                cp "$generated_file" "$HOME/.config/spotify-player/theme.toml"
                log_success "Applied spotify-player theme (restart app to apply)"
            fi
            ;;
        "rofi")
            local rofi_config="$HOME/.config/rofi/config.rasi"
            if [[ -f "$rofi_config" ]]; then
                sed -i "s/@import \".*\.rasi\"/@import \"${theme_mode}.rasi\"/" "$rofi_config"
                log_success "Applied Rofi ${theme_mode} theme"
            fi
            ;;
        "opencode")
            if [[ -d "$HOME/.config/opencode" ]] || command -v opencode &> /dev/null; then
                mkdir -p "$HOME/.config/opencode"
                cp "$generated_file" "$HOME/.config/opencode/theme.json"
                log_success "Applied opencode theme"
            fi
            ;;
        "clipse")
            if [[ -d "$HOME/.config/clipse" ]] || command -v clipse &> /dev/null; then
                mkdir -p "$HOME/.config/clipse"
                cp "$generated_file" "$HOME/.config/clipse/custom_theme.json"
                log_success "Applied clipse theme"
            fi
            ;;
        "kitty")
            if [[ -d "$HOME/.config/kitty" ]] || command -v kitty &> /dev/null; then
                mkdir -p "$HOME/.config/kitty"
                cp "$generated_file" "$HOME/.config/kitty/theme.conf"
                # Reload all kitty instances
                if pgrep -x kitty > /dev/null; then
                    for socket in /tmp/kitty-*; do
                        kitty @ --to "unix:$socket" set-colors -a -c "$generated_file" 2>/dev/null || true
                    done
                fi
                log_success "Applied kitty theme"
            fi
            ;;
        "eww")
            if [[ -d "$HOME/.config/eww" ]] || command -v eww &> /dev/null; then
                mkdir -p "$HOME/.config/eww"
                mkdir -p "$HOME/.config/eww/assets"
                cp "$generated_file" "$HOME/.config/eww/eww.scss"
                # Generate SVG corners from templates
                local bg_color=$(jq -r ".themes.${theme_mode}.background.primary" "$COLORS_FILE")
                local border_color=$(jq -r ".themes.${theme_mode}.background.overlay" "$COLORS_FILE")
                local svg_templates_dir="$TEMPLATES_DIR/eww-assets"
                if [[ -d "$svg_templates_dir" ]]; then
                    for svg_template in "$svg_templates_dir"/*.svg.template; do
                        if [[ -f "$svg_template" ]]; then
                            local svg_name=$(basename "$svg_template" .template)
                            local output_svg="$HOME/.config/eww/assets/$svg_name"
                            sed -e "s|{{background.primary}}|${bg_color}|g" \
                                -e "s|{{background.overlay}}|${border_color}|g" \
                                "$svg_template" > "$output_svg"
                        fi
                    done
                    log_info "Generated eww SVG assets"
                fi
                # Reload eww if running
                if pgrep -x eww > /dev/null; then
                    eww reload
                    log_success "Applied and reloaded eww theme"
                else
                    log_success "Applied eww theme (not running)"
                fi
            fi
            ;;
        "qutebrowser")
            if [[ -d "$HOME/.config/qutebrowser" ]] || command -v qutebrowser &> /dev/null; then
                mkdir -p "$HOME/.config/qutebrowser"
                cp "$generated_file" "$HOME/.config/qutebrowser/theme.py"
                log_success "Applied qutebrowser theme (add 'config.source(\"theme.py\")' to config.py)"
            fi
            ;;
        "qutebrowser-userstyles")
            if [[ -d "$HOME/.config/qutebrowser" ]] || command -v qutebrowser &> /dev/null; then
                mkdir -p "$HOME/.config/qutebrowser"
                cp "$generated_file" "$HOME/.config/qutebrowser/userstyles.css"
                log_success "Applied qutebrowser userstyles"
            fi
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

    # Apply themes that have generated files
    for tool_dir in "$GENERATED_DIR"/*; do
        if [[ -d "$tool_dir" ]]; then
            local tool=$(basename "$tool_dir")
            apply_tool_theme "$tool" "$theme_mode"
        fi
    done

    # Apply tools that don't need generated files (config modification only)
    apply_tool_theme "rofi" "$theme_mode"

    log_success "All themes applied for $theme_mode mode"
}

# Apply system-wide theme settings (GTK, gsettings, wezterm hot-reload)
apply_system_theme() {
    local theme_mode=$1
    local gtk_theme

    if [[ "$theme_mode" == "dark" ]]; then
        gtk_theme="prefer-dark"
    else
        gtk_theme="prefer-light"
    fi

    # Update GTK 3.0 settings
    local gtk3_settings="$HOME/.config/gtk-3.0/settings.ini"
    if [[ -f "$gtk3_settings" ]]; then
        if grep -q "gtk-application-prefer-dark-theme" "$gtk3_settings"; then
            if [[ "$theme_mode" == "dark" ]]; then
                sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=true/' "$gtk3_settings"
            else
                sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=false/' "$gtk3_settings"
            fi
        fi
        log_success "Updated GTK 3.0 settings"
    fi

    # Update GTK 4.0 settings
    local gtk4_settings="$HOME/.config/gtk-4.0/settings.ini"
    if [[ -f "$gtk4_settings" ]]; then
        if grep -q "gtk-application-prefer-dark-theme" "$gtk4_settings"; then
            if [[ "$theme_mode" == "dark" ]]; then
                sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=true/' "$gtk4_settings"
            else
                sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=false/' "$gtk4_settings"
            fi
        fi
        log_success "Updated GTK 4.0 settings"
    fi

    # Update gsettings color scheme (for GNOME/GTK apps)
    if command -v gsettings &> /dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme "$gtk_theme" 2>/dev/null || true
        log_success "Updated gsettings color-scheme"
    fi

    # Touch wezterm config to trigger hot-reload
    local wezterm_config="$HOME/.config/wezterm/wezterm.lua"
    if [[ -f "$wezterm_config" ]]; then
        touch "$wezterm_config"
        log_success "Triggered Wezterm hot-reload"
    fi
}

# Switch theme mode
switch_theme() {
    local theme_mode=$1

    if [[ "$theme_mode" != "dark" && "$theme_mode" != "light" ]]; then
        log_error "Invalid theme mode: $theme_mode. Use 'dark' or 'light'"
        return 1
    fi

    log_info "Switching to $theme_mode theme..."

    # Write theme mode to file (this triggers file watchers like Neovim)
    set_theme_mode "$theme_mode"

    # Generate and apply all themes
    generate_all "$theme_mode"
    apply_all "$theme_mode"

    # Apply system-wide settings
    apply_system_theme "$theme_mode"

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

    echo "=== Theme Status ==="
    echo "Current Theme: $current_theme"
    echo "Theme Mode File: $THEME_MODE_FILE"
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