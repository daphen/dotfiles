# Swedish Character Keyboard Layout System

## Overview
This is a two-layer system to add Swedish characters (åäö) to an ANSI keyboard layout without losing any existing functionality.

## Architecture

### Layer 1: Kanata (kanata.kbd)
Kanata intercepts physical keypresses and remaps them to different keycodes BEFORE they reach the system.

**Swedish character mappings:**
- Physical `[` key → sends `henk` keycode
- Physical `;` key → sends `slck` (Scroll Lock) keycode
- Physical `'` key → sends `pause` keycode

These keycodes are chosen because they're rarely used and don't conflict with typical app shortcuts or programming workflows.

### Layer 2: XKB (keymap.xkb)
XKB receives the keycodes from Kanata and maps them to actual characters.

**Character mappings:**
- `henk` keycode → å (lowercase) / Å (with Shift)
- `slck` keycode → ö (lowercase) / Ö (with Shift)
- `pause` keycode → ä (lowercase) / Ä (with Shift)

## Why This Two-Layer Approach?

1. **Avoids conflicts**: By using rarely-used keycodes as intermediaries (home, scroll lock, pause), we avoid conflicts with application-specific key bindings
2. **Clean separation**: Kanata handles physical key remapping, XKB handles character output
3. **Flexibility**: Easy to change either layer independently

## Additional Features in Kanata

### Home Row Mods & Layers
- `d` (hold) → activates braces layer for [] access
- `c` (hold) → activates navigation layer (hjkl arrows, quotes on io)
- `n` (hold) → activates bracket-symbols layer for []{}() access
- `caps` → tap for Esc, hold for Ctrl
- Right `shift` → when held with ö position, produces colon

### Alt/Super Swap
Physical Alt and Super (Windows/Command) keys are swapped in the base layer.

## File Locations
All keyboard-related configs are in `~/.config/kanata/`:
- Kanata config: `~/.config/kanata/kanata.kbd` - Applies to all keyboards EXCEPT Piantor
- XKB keymap: `~/.config/kanata/keymap.xkb`
- Restart script: `~/.config/kanata/restart-kanata.sh`
- This summary: `~/.config/kanata/KEYBOARD_LAYOUT_SUMMARY.md`
- Piantor config: `~/.config/kanata/kanata-piantor.kbd` - NOT USED (Piantor uses its own firmware)

Fish shell functions:
- `~/.config/fish/functions/restart_kanata.fish` - Restart Kanata
- `~/.config/fish/functions/reload_all.fish` - Restart Kanata + reload Fish

The XKB keymap is referenced in niri config at `~/.config/niri/config.kdl`

### Device Handling
The main kanata.kbd explicitly excludes the Piantor Pro so it won't interfere with the Piantor's built-in QMK/Vial firmware which handles its own layers and Swedish characters. Both old and new device names are excluded:
- Old firmware names: "beekeeb Piantor Pro", "beekeeb Piantor Pro Keyboard", etc.
- Custom firmware names: "beekeeb piantor_pro", "beekeeb piantor_pro Keyboard", etc.

### Custom Firmware (QMK/Vial)
The Piantor Pro runs custom Vial-QMK firmware built from `~/vial-qmk/keyboards/beekeeb/piantor_pro/keymaps/vial/`. Key changes from stock:
- Debounce: 15ms with `sym_eager_pk` algorithm (stock was 5ms defer, caused double keypresses)
- Vial layout backup: `~/.config/Vial/piantor-pro.vil`
- Flash via bootmagic: hold top-left key while plugging in USB, copy `.uf2` to RPI-RP2 drive

## Reloading Changes

After editing configs:
```bash
# Option 1: Use Fish function (recommended)
restart_kanata

# Option 2: Run script directly
bash ~/.config/kanata/restart-kanata.sh

# Reload niri (which will reload the XKB keymap)
niri msg action quit
```

## Troubleshooting

### Capital letters not working in specific apps (e.g., Slack, Discord)
Some applications (especially Electron apps) intercept certain keycodes for special functions:
- Insert → Often used for paste operations
- Page Down → Used for scrolling
- F11 → Fullscreen toggle

This is why we use Henk, Scroll Lock, and Pause - they're rarely intercepted by modern applications.

### To verify mappings
```bash
# Test in terminal - type the physical keys and see what appears
# Physical [ should produce å
# Physical ; should produce ö
# Physical ' should produce ä
```

## Testing Status

### Current Mapping (CONFIRMED WORKING - Nov 4, 2025)
- **å (Physical `[`)** → `henk` keycode → ✅ Working in all apps
- **ö (Physical `;`)** → `slck` keycode → ✅ Working in all apps
- **ä (Physical `'`)** → `pause` keycode → ✅ Working in all apps

**Status: FULLY OPERATIONAL** - All Swedish characters working correctly across all applications tested.

### Tested Keycodes (What Works/Doesn't Work)

| Keycode | Tested For | Result | Issue |
|---------|-----------|--------|-------|
| `f10` | å | ❌ Failed | - |
| `f11` | ö | ❌ Failed | Triggers fullscreen toggle in browsers |
| `f12` | ä | ❌ Not tested | Would trigger dev tools in browsers |
| `ins` | ö | ❌ Failed | Capital Ö doesn't work in Slack (paste operation conflict) |
| `pgdn` | ä | ❌ Failed | Doesn't work in Discord (scroll conflict) |
| `henk` | å | ✅ Works | Currently in use |
| `slck` | ö | ✅ Works | Currently in use |
| `pause` | ä | ✅ Works | Currently in use - confirmed working |

## Setup & Autostart

### Sudoers Configuration
For Kanata to start automatically without password prompts, the sudoers file must be installed:

```bash
# Install the sudoers file (one-time setup)
sudo cp ~/.config/kanata/kanata-sudoers-linux /etc/sudoers.d/kanata
sudo chmod 0440 /etc/sudoers.d/kanata

# Verify it's installed correctly
sudo visudo -c
```

This allows Kanata to run with elevated privileges (needed for keyboard interception) without requiring password input at startup.

### Autostart with Niri
Kanata is configured to start automatically when Niri launches via the `spawn-at-startup` directive in `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "bash" "-c" "/home/daphen/.config/kanata/start-kanata.sh"
```

### Piantor Pro Configuration
For the Piantor Pro keyboard, map these keycodes in your QMK/ZMK firmware:
- `KC_HENK` → for å/Å
- `KC_SLCK` → for ö/Ö
- `KC_PAUSE` → for ä/Ä

The Piantor is excluded from Kanata processing and handles Swedish characters through its own firmware.

## History
- Original setup used F10/F11/F12, but F11 triggered fullscreen toggle when typing ö
- Tried Insert for ö, but capital Ö didn't work in Slack (paste conflict)
- Tried PageDown for ä, but didn't work in Discord (scroll conflict)
- **Final solution: Henk/ScrollLock/Pause** - ✅ Confirmed working in all applications (Nov 4, 2025)
