# Quick Reference: Dotfiles Management

## Check What's Managed

```bash
ls -la ~/.config/ | grep "^l"  # Shows all symlinks (managed apps)
ls -la ~/.config/ | grep "^d"  # Shows all directories (local apps)
```

## Promote New App to Managed

```bash
# 1. Install and configure the app first
# 2. Run the helper script
~/dotfiles/promote-app-to-managed.sh <app-name>

# 3. Add to home-manager config
# 4. Rebuild
sudo nixos-rebuild switch
```

## Theme Management

```bash
cd ~/dotfiles/themes/.config/themes

# Generate and apply dark theme
./theme-manager.sh switch dark

# Generate and apply light theme
./theme-manager.sh switch light

# Toggle between modes
./theme-manager.sh toggle

# Check status
./theme-manager.sh status
```

## Git Workflow for Managed Apps

```bash
# Edit any config in ~/.config (changes go to ~/dotfiles automatically)
vim ~/.config/kitty/kitty.conf

# Commit from dotfiles
cd ~/dotfiles
git add .
git commit -m "Update kitty config"
git push
```

## See Full Guide

```bash
cat ~/dotfiles/MANAGING-APPS.md
```
