#!/usr/bin/env bash
# Clipboard history picker using rofi and cliphist with image preview

selected=$(cliphist list | rofi -dmenu -p "Clipboard")

if [[ -n "$selected" ]]; then
    echo "$selected" | cliphist decode | wl-copy
fi
