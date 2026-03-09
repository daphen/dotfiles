#!/usr/bin/env bash
# Helper script to promote an app from local to managed

APP_NAME="$1"

if [[ -z "$APP_NAME" ]]; then
    echo "Usage: $0 <app-name>"
    echo "Example: $0 newtool"
    exit 1
fi

echo "=== Promoting $APP_NAME to Managed Status ==="
echo ""

# Step 1: Check if app exists in ~/.config
if [[ ! -d "$HOME/.config/$APP_NAME" ]]; then
    echo "❌ Error: ~/.config/$APP_NAME doesn't exist"
    echo "   Install and configure the app first!"
    exit 1
fi

# Step 2: Check if already managed
if [[ -L "$HOME/.config/$APP_NAME" ]]; then
    echo "✓ $APP_NAME is already managed (symlinked)"
    exit 0
fi

echo "Step 1: Creating dotfiles structure..."
mkdir -p "$HOME/dotfiles/$APP_NAME/.config/$APP_NAME"

echo "Step 2: Copying current config to dotfiles..."
rsync -av "$HOME/.config/$APP_NAME/" "$HOME/dotfiles/$APP_NAME/.config/$APP_NAME/"

echo "Step 3: Checking for theme support..."
THEME_TEMPLATE="$HOME/dotfiles/themes/.config/themes/templates/${APP_NAME}.template"
if [[ -f "$THEME_TEMPLATE" ]]; then
    echo "   ✓ Theme template exists"
else
    echo "   ℹ No theme template (you can add one later)"
fi

echo ""
echo "=== Configuration to Add ==="
echo ""
echo "Add this to your home-manager configuration:"
echo ""
cat << NIXEOF
  # $APP_NAME
  ".config/$APP_NAME".source = config.lib.file.mkOutOfStoreSymlink "\${config.home.homeDirectory}/dotfiles/$APP_NAME/.config/$APP_NAME";
NIXEOF
echo ""

echo "=== Next Steps ==="
echo "1. Add the configuration above to your home-manager config"
echo "2. Backup current config: mv ~/.config/$APP_NAME ~/.config/${APP_NAME}.backup"
echo "3. Rebuild: sudo nixos-rebuild switch"
echo "4. Verify symlink: ls -la ~/.config/$APP_NAME"
echo "5. Test: edit files in ~/.config/$APP_NAME (changes go to ~/dotfiles)"
echo "6. Commit to git: cd ~/dotfiles && git add $APP_NAME && git commit"
