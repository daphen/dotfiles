#!/bin/bash
# Restart Kanata with single config (excludes Piantor via device exclusion)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Restarting Kanata..."

# Kill any existing Kanata instances
echo "🛑 Stopping existing Kanata processes..."
sudo pkill kanata 2>/dev/null || true

# Wait a moment for processes to fully stop
sleep 1

# Start Kanata using the start script
bash "$SCRIPT_DIR/start-kanata.sh"
