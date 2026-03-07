#!/usr/bin/env bash
# Kill any existing eww daemon instances
pkill -9 -x eww 2>/dev/null
rm -f /run/user/$(id -u)/eww-server_* 2>/dev/null
sleep 0.3

# Start daemon in background
eww daemon &

# Wait for daemon to be ready (--no-daemonize prevents spawning new daemons)
for i in {1..60}; do
    if eww --no-daemonize ping &>/dev/null; then
        break
    fi
    sleep 0.3
done

# Open all windows on monitor 0 (order matters for z-stacking: frames first, then corners on top)
eww open-many bar frame-left frame-right frame-bottom corner-left corner-right corner-bottom-left corner-bottom-right

# Only open monitor 1 windows if any external display (DP-*) is connected
if niri msg outputs 2>/dev/null | grep -qE '\(DP-[0-9]+\)'; then
    eww open-many bar-1 frame-left-1 frame-right-1 frame-bottom-1 corner-left-1 corner-right-1 corner-bottom-left-1 corner-bottom-right-1
fi
