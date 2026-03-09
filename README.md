# Arch Linux Dotfiles

My personal configuration files for Arch Linux, managed with GNU Stow.

## Contents

- **niri** - Scrollable tiling Wayland compositor configuration
- **waybar** - Status bar configuration and scripts
- **mako** - Notification daemon configuration
- **fish** - Fish shell configuration and functions
- **nvim** - Neovim configuration with plugins and custom theme
- **wezterm** - WezTerm terminal emulator configuration
- **yazi** - Terminal file manager configuration
- **kanata** - Keyboard remapping configuration
- **themes** - Centralized theme management system
- **systemd** - User systemd services
- **claude** - Claude Code hooks and commands configuration

## Installation

### Prerequisites

```bash
sudo pacman -S git stow
```

### Clone and Deploy

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# Generate theme files (required for first-time setup)
cd ~/dotfiles
./themes/.config/themes/generate-themes.sh

# Deploy all configurations
stow niri waybar mako fish nvim wezterm yazi kanata themes systemd claude

# Or deploy individual packages
stow niri  # Just the niri window manager config
```

## Packages

### niri
- Window manager configuration (`config.kdl`)
- **Scripts** (all in `.config/niri/scripts/`):
  - `niri-focus-tracker` - Window focus history tracker (with memory leak protection)
  - `niri-jump-or-exec` - Jump to or execute applications
  - `focus-workspace-down-or-monitor` - Smart workspace/monitor navigation
  - `focus-workspace-up-or-monitor` - Smart workspace/monitor navigation
  - `move-window-down-or-monitor` - Move windows across workspaces/monitors
  - `move-window-up-or-monitor` - Move windows across workspaces/monitors
  - `spawn-terminal-with-claude` - Open terminal with Claude Code
  - `spawn-terminal-with-yazi` - Open terminal with Yazi file manager
  - `spawn-terminal-with-zoxide-picker` - Open terminal with directory picker
  - `screenshot-to-clipboard` - Screenshot selection to clipboard

### waybar
- Status bar configuration
- Custom scripts for wifi and audio menus
- Niri workspace minimap

### mako
- Notification daemon configuration
- Dark theme matching system colors
- Top-right positioning with 5-second timeout
- Grouped notifications by application

### fish
- Shell configuration with custom prompt
- Theme toggling functions
- Various utility functions

### nvim
- Complete Neovim configuration with lazy.nvim plugin manager
- Custom theme integration
- LSP configuration for multiple languages
- AI tracker plugin for development notes

### wezterm
- Terminal configuration with theme integration
- Custom key bindings
- Font and appearance settings

### yazi
- Terminal file manager configuration
- Custom theme integration
- Optimized for use with niri window manager

### kanata
- Custom keyboard layout with Swedish characters
- XKB keymap configuration

### themes
- Centralized theme manager for all tools
- Dark/light mode switching
- Theme generation scripts
- **Important**: After cloning, run `cd ~/dotfiles && ./themes/.config/themes/generate-themes.sh` to generate initial theme files

### claude
- Custom hooks for enhanced functionality
- AI tracker integration for development notes
- Screenshot commands (`/ss`, `/ss2`, `/ss3`)
- Paste image functionality
- Local settings overrides

## Key Bindings

### Window Navigation
- `Super+h` - Focus column or monitor left
- `Super+l` - Focus column or monitor right
- `Super+j` - Focus workspace down (or monitor below)
- `Super+k` - Focus workspace up (or monitor above)
- `Super+Tab` - Toggle overview mode

### Window Movement
- `Super+Shift+h` - Move column left
- `Super+Shift+l` - Move column right
- `Super+Shift+w` - Close window
- `Super+Ctrl+Shift+h` - Move window to monitor left
- `Super+Ctrl+Shift+l` - Move window to monitor right
- `Super+Ctrl+Shift+j` - Move window down or to monitor below
- `Super+Ctrl+Shift+k` - Move window up or to monitor above

### Window Resizing
- `Super+Ctrl+h` - Decrease column width by 5%
- `Super+Ctrl+l` - Increase column width by 5%
- `Super+Ctrl+f` - Maximize column

### Applications (Jump-or-Exec)
- `Super+Space` - Application launcher (vicinae)
- `Super+c` - Discord (Vesktop)
- `Super+d` - WezTerm terminal (jump to existing)
- `Super+Shift+d` - WezTerm terminal (new instance)
- `Super+f` - Zen browser (jump to existing)
- `Super+Shift+f` - Zen browser (new instance)
- `Super+s` - Slack
- `Super+a` - Spotify
- `Super+t` - Microsoft Teams

### Terminal Launchers
- `Super+e` - Terminal with Yazi file manager
- `Super+r` - Terminal with Zoxide directory picker
- `Super+g` - Terminal with Claude Code

### System Controls
- `Super+Ctrl+t` - Toggle dark/light theme
- `Super+Ctrl+q` - Lock screen (swaylock)
- `Super+Alt+S` - Toggle screen reader (orca)
- `Mod+Shift+/` - Show hotkey overlay

### Screenshots
- `Print` - Interactive screenshot UI
- `Super+Print` - Screenshot entire screen
- `Super+Alt+Print` - Screenshot focused window
- `Super+Ctrl+Shift+e` - Screenshot selection to clipboard

### Utilities
- `Super+Ctrl+c` - Color picker
- `Super+Ctrl+V` - Clipboard history (vicinae)
- `Super+Ctrl+J` - Emoji picker (vicinae)
- `Super+Ctrl+B` - Bluetooth devices menu (vicinae)

### Media Keys
- `XF86AudioRaiseVolume` - Increase volume 5%
- `XF86AudioLowerVolume` - Decrease volume 5%
- `XF86AudioMute` - Toggle mute
- `XF86AudioMicMute` - Toggle microphone mute
- `XF86AudioPlay/Pause` - Play/pause media
- `XF86AudioNext` - Next track
- `XF86AudioPrev` - Previous track

### Brightness Keys
- `XF86MonBrightnessUp` - Increase screen brightness 5%
- `XF86MonBrightnessDown` - Decrease screen brightness 5%
- `XF86KbdBrightnessUp` - Increase keyboard backlight
- `XF86KbdBrightnessDown` - Decrease keyboard backlight

## Backup Existing Configs

Before deploying, backup your existing configurations:

```bash
mkdir ~/config-backup
cp -r ~/.config/niri ~/.config/waybar ~/.config/fish ~/config-backup/
```

## Restoring from Backup

If you need to restore your original configs:

```bash
# Remove symlinks
cd ~/dotfiles
stow -D niri waybar fish kanata themes systemd bin

# Restore from backup
cp -r ~/config-backup/* ~/.config/
```

## Updates

To update configurations:

1. Edit files directly (they're symlinked)
2. Commit changes:
   ```bash
   cd ~/dotfiles
   git add .
   git commit -m "Update configs"
   git push
   ```

## License

Personal configuration files - feel free to use and modify as needed.