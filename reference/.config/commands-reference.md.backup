# Common Commands Reference

Quick reference for troubleshooting and manual control.

## WiFi (NetworkManager / nmcli)

```bash
# Status
nmcli general status              # Overall network status
nmcli device status               # List all network devices
nmcli connection show             # List saved connections
nmcli device wifi list            # Scan and list available networks

# Connect / Disconnect
nmcli device wifi connect "SSID" password "PASSWORD"   # Connect to new network
nmcli connection up "CONNECTION_NAME"                   # Connect to saved network
nmcli connection down "CONNECTION_NAME"                 # Disconnect
nmcli device disconnect wlan0                           # Disconnect device

# Restart networking
nmcli networking off && nmcli networking on   # Toggle networking
nmcli radio wifi off && nmcli radio wifi on   # Toggle WiFi radio
sudo systemctl restart NetworkManager         # Full restart

# Forget / Delete connection
nmcli connection delete "CONNECTION_NAME"
```

## WiFi (iwd / iwctl) - Alternative

```bash
iwctl                             # Enter interactive mode
iwctl station wlan0 scan          # Scan for networks
iwctl station wlan0 get-networks  # List available networks
iwctl station wlan0 connect SSID  # Connect to network
iwctl station wlan0 disconnect    # Disconnect
iwctl station wlan0 show          # Show connection status
```

## Bluetooth (bluetoothctl)

```bash
bluetoothctl                      # Enter interactive mode

# Inside bluetoothctl or as one-liners:
bluetoothctl power on             # Turn on bluetooth
bluetoothctl power off            # Turn off bluetooth
bluetoothctl scan on              # Start scanning for devices
bluetoothctl scan off             # Stop scanning
bluetoothctl devices              # List known devices
bluetoothctl paired-devices       # List paired devices

# Connect / Disconnect (use MAC address)
bluetoothctl pair XX:XX:XX:XX:XX:XX      # Pair with device
bluetoothctl trust XX:XX:XX:XX:XX:XX     # Trust device (auto-connect)
bluetoothctl connect XX:XX:XX:XX:XX:XX   # Connect to device
bluetoothctl disconnect XX:XX:XX:XX:XX   # Disconnect from device
bluetoothctl remove XX:XX:XX:XX:XX:XX    # Remove/forget device

# Restart bluetooth
sudo systemctl restart bluetooth
```

## ASUS Controls (asusctl)

```bash
# Fan profiles
asusctl profile -l                # List available profiles
asusctl profile -p                # Show current profile
asusctl profile -P Quiet          # Set to Quiet
asusctl profile -P Balanced       # Set to Balanced
asusctl profile -P Performance    # Set to Performance

# Set auto-switching profiles
asusctl profile --profile-on-ac Quiet
asusctl profile --profile-on-battery Quiet

# Keyboard backlight (if supported)
asusctl led-mode -l               # List LED modes
asusctl led-mode -s static        # Set LED mode

# Service
systemctl status asusd            # Check service status
sudo systemctl restart asusd      # Restart service
```

## AMD GPU (CoreCtrl)

```bash
corectrl                          # Launch GUI
# Profiles stored in: ~/.config/corectrl/
```

## System Sensors

```bash
sensors                           # Show all temps and fan speeds
watch -n 1 sensors                # Live monitoring
```

## Audio (if using PipeWire/PulseAudio)

```bash
# PipeWire
wpctl status                      # Show audio devices
wpctl get-volume @DEFAULT_AUDIO_SINK@     # Get volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50% # Set volume
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle # Toggle mute

# List and switch outputs
pactl list short sinks            # List audio outputs
pactl set-default-sink SINK_NAME  # Set default output

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Display / Monitor

```bash
# Niri (check your niri config for keybinds)
# Config location: ~/.config/niri/config.kdl

# Brightness (if supported)
brightnessctl list                # List brightness devices
brightnessctl set 50%             # Set brightness
brightnessctl set +10%            # Increase
brightnessctl set 10%-            # Decrease
```

## Services Quick Reference

```bash
# Check status
systemctl status SERVICE_NAME
systemctl --user status SERVICE_NAME  # For user services

# Start/Stop/Restart
sudo systemctl start SERVICE_NAME
sudo systemctl stop SERVICE_NAME
sudo systemctl restart SERVICE_NAME

# Enable/Disable on boot
sudo systemctl enable SERVICE_NAME
sudo systemctl disable SERVICE_NAME

# Common services
# - NetworkManager (WiFi)
# - bluetooth (Bluetooth)
# - asusd (ASUS controls)
# - pipewire, wireplumber (Audio)
```

## Troubleshooting

### WiFi won't connect
```bash
nmcli device status               # Check device state
nmcli radio wifi                  # Check if WiFi radio is enabled
sudo rfkill list                  # Check for hardware/software blocks
sudo rfkill unblock wifi          # Unblock if blocked
sudo systemctl restart NetworkManager
```

### Bluetooth device won't connect
```bash
bluetoothctl power off && bluetoothctl power on
bluetoothctl remove XX:XX:XX:XX:XX:XX   # Remove and re-pair
sudo systemctl restart bluetooth
```

### Fans stuck on high
```bash
asusctl profile -P Quiet          # Force quiet mode
sudo systemctl restart asusd      # Restart ASUS daemon
```

### No audio output
```bash
wpctl status                      # Check PipeWire status
systemctl --user restart pipewire pipewire-pulse wireplumber
```

---

## Niri (Window Manager)

```bash
# Info commands
niri msg outputs                  # List monitors (get names for config)
niri msg workspaces               # List workspaces
niri msg focused-window           # Show focused window info
niri msg windows                  # List all windows

# Actions
niri msg action quit              # Exit niri
niri msg action power-off-monitors  # Turn off monitors
niri msg action spawn "app"       # Launch app

# Config
# Location: ~/.config/niri/config.kdl
# Reload: Save file - niri auto-reloads
```

### Niri Keybinds (your config)

| Keybind | Action |
|---------|--------|
| `Super+Space` | App launcher (rofi) |
| `Super+Tab` | Overview mode |
| `Super+h/l` | Focus left/right window |
| `Super+j/k` | Focus workspace down/up |
| `Super+Shift+h/l` | Move window left/right |
| `Super+Ctrl+Shift+h/l` | Move window to monitor left/right |
| `Super+Ctrl+Shift+j/k` | Move window to workspace down/up |
| `Super+Ctrl+h/l` | Resize window narrower/wider |
| `Super+Ctrl+f` | Maximize window |
| `Super+Shift+w` | Close window |
| `Super+Ctrl+q` | Lock screen (swaylock) |
| `Print` | Screenshot (interactive) |
| `Super+Print` | Screenshot entire screen |
| `Super+Alt+Print` | Screenshot focused window |
| `Super+Ctrl+Shift+e` | Screenshot selection to clipboard |
| `Super+Ctrl+c` | Color picker |
| `Super+Ctrl+V` | Clipboard history |
| `Super+Ctrl+J` | Emoji picker (rofimoji) |
| `Super+Ctrl+B` | Bluetooth menu (rofi-bluetooth) |
| `Super+Ctrl+t` | Toggle theme |

### App Shortcuts

| Keybind | App |
|---------|-----|
| `Super+d` | WezTerm (jump or focus) |
| `Super+Shift+d` | WezTerm (new instance) |
| `Super+f` | Zen Browser (jump or focus) |
| `Super+Shift+f` | Zen Browser (new instance) |
| `Super+e` | Yazi file manager |
| `Super+r` | Zoxide directory picker |
| `Super+g` | Claude terminal |
| `Super+s` | Slack |
| `Super+a` | Spotify |
| `Super+c` | Vesktop (Discord) |
| `Super+t` | Microsoft Teams |

## Screenshots & Screen Capture

```bash
# Using grim + slurp
grim                              # Screenshot entire screen
grim -g "$(slurp)"                # Screenshot selected area
grim -g "$(slurp)" - | wl-copy    # Screenshot to clipboard
grim -o eDP-1                     # Screenshot specific output

# Screenshot focused window
grim -g "$(niri msg focused-window | jq -r '.geometry | "\(.x),\(.y) \(.width)x\(.height)"')"
```

## Clipboard (cliphist + wl-clipboard)

```bash
# Copy/Paste
wl-copy "text"                    # Copy text to clipboard
wl-paste                          # Paste from clipboard
wl-copy < file.txt                # Copy file contents

# Clipboard history
cliphist list                     # List clipboard history
cliphist list | rofi -dmenu | cliphist decode | wl-copy  # Pick from history
cliphist wipe                     # Clear history

# Clear specific entry
cliphist list | rofi -dmenu | cliphist delete
```

## Rofi (App Launcher)

```bash
rofi -show drun                   # Application launcher
rofi -show run                    # Run command
rofi -show window                 # Window switcher
rofi -show ssh                    # SSH connections
rofi -dmenu                       # Generic menu (pipe input)

# Config location: ~/.config/rofi/config.rasi
# Themes: ~/.config/rofi/dark.rasi, ~/.config/rofi/light.rasi
```

## Waybar

```bash
# Restart waybar
pkill waybar && waybar &

# Config location: ~/.config/waybar/config
# Style: ~/.config/waybar/style.css
```

## Mako (Notifications)

```bash
makoctl dismiss                   # Dismiss last notification
makoctl dismiss --all             # Dismiss all notifications
makoctl restore                   # Restore last dismissed
makoctl invoke                    # Invoke default action
makoctl mode -a do-not-disturb    # Enable DND
makoctl mode -r do-not-disturb    # Disable DND

# Config: ~/.config/mako/config
# Reload: makoctl reload
```

## Swaylock (Screen Lock)

```bash
swaylock                          # Lock screen
swaylock -f                       # Fork (background)
swaylock -c 000000                # Lock with solid color

# With swaylock-effects
swaylock --clock --indicator      # Show clock and indicator
swaylock --screenshots --effect-blur 7x5  # Blur screenshot
```

## Kanata (Keyboard Remapper)

```bash
# Config: ~/.config/kanata/kanata.kbd
# Start script: ~/.config/kanata/start-kanata.sh

# Restart kanata
~/.config/kanata/restart-kanata.sh
# Or manually:
pkill kanata
sudo kanata -c ~/.config/kanata/kanata.kbd &
```

## Espanso (Text Expander)

```bash
espanso status                    # Check if running
espanso start                     # Start espanso
espanso stop                      # Stop espanso
espanso restart                   # Restart espanso
espanso edit                      # Edit config

# Config: ~/.config/espanso/config/
# Matches: ~/.config/espanso/match/
```

## Wallpaper (waypaper + swaybg)

```bash
waypaper                          # Open GUI wallpaper picker
waypaper --restore                # Restore last wallpaper

# Manual with swaybg
swaybg -i /path/to/image.jpg -m fill &
pkill swaybg                      # Kill current wallpaper
```

## Media Controls (playerctl)

```bash
playerctl play-pause              # Toggle play/pause
playerctl next                    # Next track
playerctl previous                # Previous track
playerctl status                  # Show playing status
playerctl metadata                # Show track metadata
playerctl -l                      # List available players
playerctl -p spotify play-pause   # Control specific player
```

## Package Management (pacman/yay)

```bash
# Pacman (official repos)
sudo pacman -Syu                  # Update system
sudo pacman -S package            # Install package
sudo pacman -Rs package           # Remove package + deps
sudo pacman -Ss keyword           # Search packages
sudo pacman -Q                    # List installed packages
sudo pacman -Qe                   # List explicitly installed
sudo pacman -Qdtq                 # List orphans
sudo pacman -Rns $(pacman -Qdtq)  # Remove orphans

# Yay (AUR)
yay -S package                    # Install from AUR
yay -Ss keyword                   # Search AUR + repos
yay -Syu                          # Update all (including AUR)
yay -Yc                           # Clean unneeded dependencies

# Cache cleanup
sudo pacman -Sc                   # Clear old package cache
sudo pacman -Scc                  # Clear all cache (careful!)
```

## Troubleshooting (Additional)

### Niri not responding
```bash
# Switch to TTY and restart
Ctrl+Alt+F2                       # Switch to TTY2
pkill niri
niri                              # Restart niri
```

### Waybar missing/broken
```bash
pkill waybar
waybar &
# Check for errors in: journalctl --user -u waybar
```

### Kanata not working
```bash
# Check if running
pgrep kanata
# Restart
~/.config/kanata/restart-kanata.sh
# Check permissions (needs input group or sudoers)
```

### Clipboard not working
```bash
# Restart clipboard watchers
pkill wl-paste
wl-paste --watch cliphist store &
wl-paste --primary --watch cliphist store &
```

### Screen lock not working
```bash
swaylock -f --debug               # Run with debug output
# Check if swayidle is blocking
pkill swayidle
```

---

## GNU Stow (Dotfiles Management)

Dotfiles location: `~/dotfiles/`

### Structure
Each package follows this structure:
```
~/dotfiles/
├── package-name/
│   └── .config/
│       └── app-name/
│           └── config-file
```

### Current Packages
| Package | Contents |
|---------|----------|
| `claude` | Claude Code settings |
| `fish` | Fish shell config |
| `kanata` | Keyboard remapper config |
| `mako` | Notification daemon config |
| `niri` | Window manager config + scripts |
| `nvim` | Neovim config |
| `reference` | This commands reference file |
| `systemd` | User systemd services |
| `themes` | Theme files |
| `waybar` | Status bar config + scripts |
| `wezterm` | Terminal emulator config |
| `yazi` | File manager config |

### Commands

```bash
# Stow a package (create symlinks)
cd ~/dotfiles && stow package-name

# Unstow a package (remove symlinks)
cd ~/dotfiles && stow -D package-name

# Restow (unstow + stow, useful after changes)
cd ~/dotfiles && stow -R package-name

# Stow all packages
cd ~/dotfiles && stow */

# Preview what stow would do (dry run)
cd ~/dotfiles && stow -n -v package-name

# Force stow (adopt existing files)
cd ~/dotfiles && stow --adopt package-name
# WARNING: --adopt moves existing files INTO the stow package

# Check for conflicts
cd ~/dotfiles && stow -n -v */ 2>&1 | grep -i conflict
```

### Adding a New Config to Stow

```bash
# 1. Create package structure
mkdir -p ~/dotfiles/newapp/.config/newapp

# 2. Move existing config
mv ~/.config/newapp/* ~/dotfiles/newapp/.config/newapp/

# 3. Remove empty original directory
rmdir ~/.config/newapp

# 4. Stow the package
cd ~/dotfiles && stow newapp

# 5. Verify symlink
ls -la ~/.config/newapp
```

### Troubleshooting Stow

```bash
# "CONFLICT" error - file already exists
# Option 1: Remove existing file first
rm ~/.config/app/config
cd ~/dotfiles && stow app

# Option 2: Adopt existing file into stow
cd ~/dotfiles && stow --adopt app
# Then check git diff to see if you want to keep changes

# "directory not empty" error
# The target directory has files not managed by stow
ls ~/.config/app/  # Check what's there
```
