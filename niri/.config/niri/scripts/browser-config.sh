#!/usr/bin/env bash
# Single source of truth for the daily browser. Sourced by
# browser-personal, browser-work, browser-dispatch, chromium-launch,
# and sync-bookmarks. To switch browsers — provided the new browser is
# Chromium-derived and supports --profile-directory + --class — edit
# only this file.
#
# Tested switches: Vivaldi ↔ Helium (both Chromium-based, identical
# CLI). Brave/Chrome/Edge would also work. Firefox needs different
# launcher logic (no --class, profile flag is -P) so this config
# isn't enough for that switch.

# Path to the browser binary.
BROWSER_BIN="/etc/profiles/per-user/daphen/bin/helium"

# Wayland app-id assigned via --class. KEPT STABLE across browser
# switches (it's just a label) so niri window-rules and ws-focus's
# BROWSER_WORK_CLASSES never need to change.
BROWSER_CLASS_PERSONAL="browser-personal"
BROWSER_CLASS_WORK="browser-work"

# Profile-directory names INSIDE the browser. Browser-specific. Most
# Chromium derivatives use "Default" and "Profile 2" by default.
BROWSER_PROFILE_PERSONAL="Default"
BROWSER_PROFILE_WORK="Profile 2"

# Browser config root — where Bookmarks / Preferences live. Used by
# sync-bookmarks. Browser-specific.
BROWSER_CONFIG_ROOT="$HOME/.config/net.imput.helium"

# Bare process name for `pgrep` (used by sync-bookmarks to detect a
# running browser before overwriting Bookmarks). Browser-specific.
BROWSER_PROCESS_NAME="helium"
