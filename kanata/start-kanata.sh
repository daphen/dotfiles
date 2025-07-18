#!/bin/bash

# Start Kanata with the configuration
# Make sure to grant accessibility permissions first!

CONFIG_FILE="$HOME/.config/kanata/kanata.kbd"

echo "Starting Kanata with homerow mods..."
echo "Press Ctrl+C to stop"
echo ""
echo "Configuration: $CONFIG_FILE"
echo ""

# Run Kanata
kanata --cfg "$CONFIG_FILE"