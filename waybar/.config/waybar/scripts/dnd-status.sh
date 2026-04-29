#!/usr/bin/env bash
# Waybar custom module: shows a moon glyph when mako's
# do-not-disturb mode is active. Hides itself otherwise.

modes=$(makoctl mode 2>/dev/null || true)
if printf '%s\n' "$modes" | grep -qx 'do-not-disturb'; then
    printf '{"text":"󰂛","class":"active","tooltip":"Do Not Disturb on (click to toggle)"}\n'
else
    printf '{"text":"","class":"empty","tooltip":""}\n'
fi
