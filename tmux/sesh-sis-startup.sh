#!/bin/bash
# Startup script for SiS session with custom layout

# Create right pane (35% width) and run opencode
tmux split-window -h -p 35 "opencode"

# Select the left pane (nvim)
tmux select-pane -L

# Start nvim in the current pane
exec nvim