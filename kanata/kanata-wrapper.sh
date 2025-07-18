#!/bin/bash

# Kanata wrapper script for LaunchAgent
# This script uses the sudoers rules to run kanata without password

CONFIG_FILE="$HOME/.config/kanata/kanata.kbd"
LOG_FILE="/tmp/kanata.log"

# Use sudo but it should not prompt for password due to sudoers rules
exec sudo /opt/homebrew/bin/kanata --cfg "$CONFIG_FILE" --port 5829 >> "$LOG_FILE" 2>&1