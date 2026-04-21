#!/bin/bash
# Background sync daemon - pushes to GitHub every 1 minute
INTERVAL=60  # 1 minute in seconds

HERMES_HOME="$(cd "$(dirname "$0")" && pwd)"

while true; do
    sleep $INTERVAL
    "$HERMES_HOME/auto-sync.sh"
done
