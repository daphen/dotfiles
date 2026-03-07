#!/usr/bin/env bash

# Start Kanata with the configuration
# Runs in background with sudo (requires sudoers configuration)

CONFIG_FILE="$HOME/.config/kanata/kanata.kbd"
LOG_FILE="/tmp/kanata.log"

echo "🚀 Starting Kanata..."
echo "📝 Config: $CONFIG_FILE"
echo "📋 Logs: $LOG_FILE"

# Run Kanata in background with sudo (use full paths for sudoers compatibility)
sudo nohup kanata --cfg "$CONFIG_FILE" > "$LOG_FILE" 2>&1 &
KANATA_PID=$!

# Wait a moment and check if it started
sleep 1

if pgrep -x kanata > /dev/null; then
    echo "✅ Kanata started successfully!"
    echo "🔍 Check status with: ps aux | grep kanata"
else
    echo "❌ Failed to start Kanata. Check logs: $LOG_FILE"
    tail -10 "$LOG_FILE"
    exit 1
fi