#!/usr/bin/env bash

# Generate both light and dark themes, then apply the current one

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read current theme mode
CURRENT_THEME="dark"
if [[ -f "$HOME/.config/theme_mode" ]]; then
    CURRENT_THEME=$(cat "$HOME/.config/theme_mode")
fi

echo "Generating and applying themes (current: $CURRENT_THEME)..."
echo ""

# Generate both themes (so both files exist for toggling)
echo "Generating dark theme..."
"$SCRIPT_DIR/theme-manager.sh" generate dark
echo ""

echo "Generating light theme..."
"$SCRIPT_DIR/theme-manager.sh" generate light
echo ""

# Only apply the current theme
echo "Applying $CURRENT_THEME theme..."
"$SCRIPT_DIR/theme-manager.sh" apply "$CURRENT_THEME"
echo ""

echo "Done! Both themes generated, $CURRENT_THEME applied."
echo "Use 'toggle_theme' to switch between them."