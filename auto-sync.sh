#!/bin/bash
# Auto-sync hermes-home to GitHub every 1 minute
# Runs via sync-daemon.py

HERMES_HOME="$(cd "$(dirname "$0")" && pwd)"
cd "$HERMES_HOME" || exit 1

# Ensure git won't hang waiting for interactive auth
export GIT_TERMINAL_PROMPT=0

# Add all changes
git add -A 2>/dev/null

# Check if there are changes to commit
if git diff --cached --quiet 2>/dev/null; then
    exit 0
fi

# Commit and push
git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null
git push origin main 2>/dev/null

echo "$(date): Synced to GitHub" >> "$HERMES_HOME/sync.log"
