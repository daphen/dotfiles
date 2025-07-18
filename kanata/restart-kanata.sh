#!/bin/bash

# Restart Kanata script
# This stops any running Kanata processes and starts a new one

CONFIG_FILE="$HOME/.config/kanata/kanata.kbd"
LOG_FILE="/tmp/kanata.log"

echo "🔄 Restarting Kanata..."

# Stop any existing Kanata processes
echo "🛑 Stopping existing Kanata processes..."
sudo -v  # Refresh sudo timestamp
sudo pkill kanata 2>/dev/null || true

# Wait a moment for processes to stop
sleep 1

# Start Kanata in background
echo "🚀 Starting Kanata with config: $CONFIG_FILE"
sudo nohup kanata --cfg "$CONFIG_FILE" --port 5829 > "$LOG_FILE" 2>&1 &

# Wait a moment and check if it started successfully
sleep 2

if pgrep -x kanata > /dev/null; then
    echo "✅ Kanata restarted successfully!"
    echo "📝 Logs: $LOG_FILE"
    echo "🔍 Check status with: ps aux | grep kanata"
else
    echo "❌ Failed to start Kanata. Check logs: $LOG_FILE"
    tail -10 "$LOG_FILE"
    exit 1
fi