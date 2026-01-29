#!/bin/bash
# Async weather fetcher with caching
CACHE_FILE="/tmp/eww-weather-cache"

# If cache exists and is less than 30 minutes old, use it
if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt 1800 ]]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Try to fetch weather with timeout
weather=$(curl -s --connect-timeout 2 --max-time 5 'wttr.in/Stockholm?format=%t' 2>/dev/null)

if [[ -n "$weather" && "$weather" != *"Unknown"* ]]; then
    echo "$weather" > "$CACHE_FILE"
    echo "$weather"
else
    # Use cached value if available, otherwise show placeholder
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo "N/A"
    fi
fi
