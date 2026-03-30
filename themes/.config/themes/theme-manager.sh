#!/usr/bin/env bash

# Theme Manager - Centralized theme management for dotfiles
# https://github.com/daphen/theme-generator

# Don't use set -e: individual tool apply failures shouldn't abort the whole script

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

THEMES_DIR="$SCRIPT_DIR"
COLORS_FILE="$THEMES_DIR/colors.json"
TEMPLATES_DIR="$THEMES_DIR/templates"
GENERATED_DIR="$THEMES_DIR/generated"

# Detect dotfiles directory (for stow-managed configs)
# Assumes dotfiles is in ~/dotfiles or find it from the themes directory
if [[ -d "$HOME/dotfiles" ]]; then
    DOTFILES_DIR="$HOME/dotfiles"
else
    # Fallback: derive from SCRIPT_DIR (themes/.config/themes -> dotfiles root)
    DOTFILES_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi

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
    python3 "$THEMES_DIR/theme-processor.py" "$template_file" "$COLORS_FILE" "$theme_mode" "$output_file" "$tool"
    
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

# Helper: Determine target location for a tool
# Returns 0 and sets $target_dir and $is_managed if found, 1 otherwise
get_tool_target() {
    local tool=$1
    local dotfiles_path="$DOTFILES_DIR/${tool}/.config/${tool}"
    local local_path="$HOME/.config/${tool}"
    
    # Check if ~/.config/${tool} is a symlink (managed by home-manager/stow)
    # If so, write to dotfiles source. Otherwise write to ~/.config directly.
    if [[ -L "$local_path" ]] && [[ -d "$dotfiles_path" ]]; then
        # App is managed: ~/.config is symlinked and dotfiles exists
        target_dir="$dotfiles_path"
        is_managed=true
        return 0
    elif [[ -d "$local_path" ]]; then
        # App exists locally but not managed
        target_dir="$local_path"
        is_managed=false
        return 0
    else
        return 1
    fi
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
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir/colors"
                cp "$generated_file" "$target_dir/colors/custom-theme-${theme_mode}.lua"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied Neovim ${theme_mode} theme ($label)"
            fi
            ;;
        "mako")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/config"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                if pgrep -x mako > /dev/null; then
                    makoctl reload
                    log_success "Applied and reloaded Mako theme ($label)"
                else
                    log_success "Applied Mako theme ($label, not running)"
                fi
            fi
            ;;
        "waybar")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/style.css"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                if pgrep -x waybar > /dev/null; then
                    killall -SIGUSR2 waybar
                    log_success "Applied and reloaded Waybar theme ($label)"
                else
                    log_success "Applied Waybar theme ($label, not running)"
                fi
            fi
            ;;
        "fish")
            if command -v fish &> /dev/null; then
                log_success "Fish theme generated (will be applied by Fish shells)"
            fi
            ;;
        "ghostty")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir/themes"
                cp "$generated_file" "$target_dir/themes/$theme_mode"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied Ghostty theme ($label)"
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
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir/colors"
                cp "$generated_file" "$target_dir/colors/${theme_mode}.lua"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied Wezterm ${theme_mode} theme ($label)"
            fi
            ;;
        "spotify-player")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/theme.toml"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied spotify-player theme ($label, restart required)"
            fi
            ;;
        "rofi")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/theme.rasi"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied Rofi ${theme_mode} theme ($label)"
            fi
            ;;
        "opencode")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir/themes"
                cp -f "$generated_file" "$target_dir/themes/customtheme.json" 2>/dev/null || true
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied opencode theme ($label)"
            fi
            ;;
        "clipse")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/custom_theme.json"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied clipse theme ($label)"
            fi
            ;;
        "kitty")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/theme.conf"
                # Reload all kitty instances
                if pgrep -x kitty > /dev/null; then
                    for socket in /tmp/kitty-*; do
                        kitty @ --to "unix:$socket" set-colors -a -c "$generated_file" 2>/dev/null || true
                    done
                fi
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied kitty theme ($label)"
            fi
            ;;
        "eww")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                mkdir -p "$target_dir/assets"
                cp "$generated_file" "$target_dir/eww.scss"
                # Generate SVG corners from templates
                local bg_color=$(jq -r ".themes.${theme_mode}.background.primary" "$COLORS_FILE")
                local border_color=$(jq -r ".themes.${theme_mode}.background.overlay" "$COLORS_FILE")
                local svg_templates_dir="$TEMPLATES_DIR/eww-assets"
                if [[ -d "$svg_templates_dir" ]]; then
                    for svg_template in "$svg_templates_dir"/*.svg.template; do
                        if [[ -f "$svg_template" ]]; then
                            local svg_name=$(basename "$svg_template" .template)
                            local output_svg="$target_dir/assets/$svg_name"
                            sed -e "s|{{background.primary}}|${bg_color}|g" \
                                -e "s|{{background.overlay}}|${border_color}|g" \
                                "$svg_template" > "$output_svg"
                        fi
                    done
                    log_info "Generated eww SVG assets"
                fi
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                # Reload eww if running
                if pgrep -x eww > /dev/null; then
                    eww reload
                    log_success "Applied and reloaded eww theme ($label)"
                else
                    log_success "Applied eww theme ($label, not running)"
                fi
            fi
            ;;
        "qutebrowser")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/theme.py"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied qutebrowser theme ($label)"
            fi
            ;;
        "qutebrowser-userstyles")
            # Special case: uses qutebrowser's directory
            local target_dir is_managed
            if get_tool_target "qutebrowser"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/userstyles.css"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied qutebrowser userstyles ($label)"
            fi
            ;;
        "swaylock")
            local target_dir is_managed
            if get_tool_target "$tool"; then
                mkdir -p "$target_dir"
                cp "$generated_file" "$target_dir/config"
                local label=$([[ "$is_managed" == true ]] && echo "managed" || echo "local")
                log_success "Applied swaylock theme ($label)"
            fi
            ;;
        "gtk")
            # Apply GTK CSS to both GTK 3.0 and GTK 4.0
            local gtk3_dir="$HOME/.config/gtk-3.0"
            local gtk4_dir="$HOME/.config/gtk-4.0"
            mkdir -p "$gtk3_dir" "$gtk4_dir"
            cp "$generated_file" "$gtk3_dir/gtk.css"
            cp "$generated_file" "$gtk4_dir/gtk.css"

            # Write settings.ini for both versions
            local dark_pref="false"
            local gtk_theme_name="Adwaita"
            if [[ "$theme_mode" == "dark" ]]; then
                dark_pref="true"
                gtk_theme_name="Adwaita-dark"
            fi
            for settings_dir in "$gtk3_dir" "$gtk4_dir"; do
                cat > "$settings_dir/settings.ini" << EOF
[Settings]
gtk-application-prefer-dark-theme=${dark_pref}
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-theme-name=${gtk_theme_name}
gtk-font-name=GeistMono Nerd Font 11
EOF
            done
            log_success "Applied GTK theme (gtk-3.0 + gtk-4.0)"
            ;;
        "kvantum")
            # Apply Kvantum theme for Qt apps (polkit agent, etc.)
            local kvantum_dir="$HOME/.config/Kvantum/CustomTheme"
            mkdir -p "$kvantum_dir"
            cp "$generated_file" "$kvantum_dir/CustomTheme.kvconfig"

            # Set CustomTheme as the active Kvantum theme
            mkdir -p "$HOME/.config/Kvantum"
            cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << EOF
[General]
theme=CustomTheme
EOF

            # Create minimal SVG (Kvantum requires one, uses fallback rendering without it)
            if [[ ! -f "$kvantum_dir/CustomTheme.svg" ]]; then
                cat > "$kvantum_dir/CustomTheme.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"><rect width="1" height="1" fill="none"/></svg>
SVGEOF
            fi

            log_success "Applied Kvantum Qt theme"
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

    log_success "All themes applied for $theme_mode mode"
}

# Apply system-wide theme settings (gsettings, wezterm hot-reload)
apply_system_theme() {
    local theme_mode=$1
    local gtk_theme

    if [[ "$theme_mode" == "dark" ]]; then
        gtk_theme="prefer-dark"
    else
        gtk_theme="prefer-light"
    fi

    # GTK settings.ini is now handled by the "gtk" apply case above

    # Update gsettings color scheme (for GNOME/GTK apps)
    if command -v gsettings &> /dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme "$gtk_theme" 2>/dev/null || true
        log_success "Updated gsettings color-scheme"
    fi

    # Set Qt platform theme to kvantum
    # (actual env vars are set in NixOS config, this is just a reminder log)
    if [[ -f "$HOME/.config/Kvantum/kvantum.kvconfig" ]]; then
        log_success "Kvantum Qt theme is configured"
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