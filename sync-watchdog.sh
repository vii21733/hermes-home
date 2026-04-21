#!/bin/bash
# Sync watchdog - ensures sync-daemon stays alive
# Checks every 2 minutes and restarts if dead

HERMES_HOME="/home/z/my-project/hermes-home"
PID_FILE="$HERMES_HOME/sync-daemon.pid"

while true; do
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            # Daemon is alive, just wait
            sleep 120
            continue
        fi
    fi
    
    # Daemon is dead, restart it
    echo "$(date): Restarting sync daemon" >> "$HERMES_HOME/sync.log"
    nohup /bin/bash "$HERMES_HOME/sync-daemon.sh" > /dev/null 2>&1 &
    sleep 120
done
