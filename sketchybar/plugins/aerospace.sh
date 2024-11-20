#!/usr/bin/env bash

CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

function get_icon() {
  echo "DEBUG: Getting icon for workspace: $1" >&2
  case "$1" in
    "A") ICON="󱄄" ;;
    "F") ICON="" ;;
    "C") ICON="󰻞" ;;
    "P") ICON="" ;;
    "M") ICON="" ;;
    "G") ICON="" ;;
    "D") ICON="" ;;
    *) echo "$1" ;;
  esac
  printf "DEBUG: Assigned icon for %s: %s\n" "$1" "$ICON" >&2
  echo "$ICON"
}


# Normal operation
WORKSPACE=$(echo "$NAME" | cut -d'.' -f2)
ICON=$(get_icon "$WORKSPACE")

if [ "$CURRENT_WORKSPACE" = "$WORKSPACE" ]; then
  sketchybar --set "$NAME" icon="$ICON" icon.color=0xffffffff background.drawing=on
else
  sketchybar --set "$NAME" icon="$ICON" icon.color=0x88ffffff background.drawing=off
fi
