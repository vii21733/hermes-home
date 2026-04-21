#!/bin/bash
# Background sync daemon - pushes to GitHub every 30 minutes
INTERVAL=1800  # 30 minutes in seconds

while true; do
    sleep $INTERVAL
    /home/z/my-project/hermes-home/auto-sync.sh
done
