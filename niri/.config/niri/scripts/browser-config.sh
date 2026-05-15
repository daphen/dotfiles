#!/usr/bin/env bash
# Single source of truth for the daily browser. Sourced by
# browser-personal, browser-work, browser-dispatch, chromium-launch,
# browser-work-new, and sync-bookmarks.
#
# Profiles run as separate processes via --user-data-dir so Chromium's
# "first-launch wins" --class quirk doesn't apply: each profile has
# its own master process and gets its own --class correctly. Side
# benefits: theme/extension restarts only affect one profile, force-
# quitting work doesn't kill personal, etc.
#
# Tested switches: Vivaldi ↔ Helium (both Chromium-based, identical
# CLI). Brave/Chrome/Edge would also work. Firefox needs different
# launcher logic (no --class, profile flag is -P) so this config
# isn't enough for that switch.

# Path to the browser binary.
BROWSER_BIN="/etc/profiles/per-user/daphen/bin/helium"

# Wayland app-id assigned via --class. KEPT STABLE across browser
# switches (it's just a label) so niri window-rules and ws-focus's
# BROWSER_CLASSES never need to change.
BROWSER_CLASS_PERSONAL="browser-personal"
BROWSER_CLASS_WORK="browser-work"

# Per-profile data dirs. Each is its own Chromium "data root" with a
# Default/ subdir inside. The pre-split layout had everything under
# ~/.config/net.imput.helium/{Default, Profile 2} — that's preserved
# only as a migration source.
BROWSER_USER_DATA_PERSONAL="$HOME/.config/helium-personal"
BROWSER_USER_DATA_WORK="$HOME/.config/helium-work"

# Profile-directory name INSIDE each data-dir. Always "Default" now
# that we have separate data-dirs per profile.
BROWSER_PROFILE="Default"

# sync-bookmarks compatibility: previously a single CONFIG_ROOT pointed
# at the shared data-dir. Keep it pointing at the personal data-dir
# since that's where the synced Bookmarks live (work profile doesn't
# use the bookmark sync workflow).
BROWSER_CONFIG_ROOT="$BROWSER_USER_DATA_PERSONAL"

# Bare process name for `pgrep` (used by sync-bookmarks to detect a
# running browser before overwriting Bookmarks). Browser-specific.
BROWSER_PROCESS_NAME="helium"

# Flags passed to every Helium invocation. Disable AsyncDns so the
# browser uses glibc's resolver instead of its own — glibc honors the
# unloaded-IPv6-module state and skips ::1; the built-in resolver
# adds it via RFC 6761 and pays a Happy Eyeballs penalty per fetch.
BROWSER_FLAGS=(
    --disable-features=AsyncDns
)
