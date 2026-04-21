#!/bin/bash
# Bootstrap script - starts the Python keeper if it's not already running
# Called from .bashrc or manually

HERMES_HOME="/home/z/my-project/hermes-home"
KEEPER="$HERMES_HOME/hermes-keeper.py"
PYTHON="/home/z/my-project/hermes-agent/venv/bin/python3"
LOG_DIR="$HERMES_HOME/logs"
LOG_FILE="$LOG_DIR/bootstrap.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# Check if keeper is already running
if [ -f "$HERMES_HOME/keeper.pid" ]; then
    KP=$(cat "$HERMES_HOME/keeper.pid" 2>/dev/null || true)
    if [ -n "$KP" ] && kill -0 "$KP" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Keeper already running (PID $KP)" >> "$LOG_FILE"
        exit 0
    fi
fi

# Start the Python keeper (it daemonizes itself via double-fork)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting keeper..." >> "$LOG_FILE"
"$PYTHON" "$KEEPER" >> "$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Keeper launched" >> "$LOG_FILE"
