#!/bin/bash

# Start kanata-tray with custom config directory
# This keeps everything contained in ~/.config/kanata/

export KANATA_TRAY_CONFIG_DIR="$HOME/.config/kanata/tray-config"
export KANATA_TRAY_LOG_DIR="$HOME/.config/kanata/logs"

# Create log directory if it doesn't exist
mkdir -p "$KANATA_TRAY_LOG_DIR"

echo "Starting kanata-tray..."
echo "Config dir: $KANATA_TRAY_CONFIG_DIR"
echo "Log dir: $KANATA_TRAY_LOG_DIR"
echo ""
echo "A tray icon should appear in your menu bar."
echo "Right-click it to start/stop Kanata or configure settings."

exec "$HOME/.config/kanata/bin/kanata-tray"