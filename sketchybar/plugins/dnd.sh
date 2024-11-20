#!/usr/bin/env bash

# Check DND status using defaults command
if [ "$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes")" = "1" ]; then
  sketchybar --set dnd icon="󰽧" icon.color=0xffffffff
else
  sketchybar --set dnd icon="" icon.color=0xffffffff
fi
