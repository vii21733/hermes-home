#!/bin/bash
# Background sync daemon - pushes to GitHub every 1 minute
# Designed to be resilient: auto-restarts on errors, logs activity

INTERVAL=60  # 1 minute in seconds
HERMES_HOME="/home/z/my-project/hermes-home"
SYNC_LOG="$HERMES_HOME/sync.log"

# Write PID file so we can track it
echo $$ > "$HERMES_HOME/sync-daemon.pid" 2>/dev/null

while true; do
    sleep $INTERVAL
    
    # Run sync
    if ! bash "$HERMES_HOME/auto-sync.sh" 2>/dev/null; then
        echo "$(date): Sync failed, retrying next cycle" >> "$SYNC_LOG"
    fi
done
