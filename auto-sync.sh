#!/bin/bash
# Auto-sync hermes-home to GitHub every 30 mins
# Runs via cron

cd /home/z/my-project/hermes-home || exit 1

# Add all changes
git add -A 2>/dev/null

# Check if there are changes to commit
if git diff --cached --quiet 2>/dev/null; then
    echo "$(date): No changes to sync" >> /home/z/my-project/hermes-home/sync.log
    exit 0
fi

# Commit and push
git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
git push origin main 2>/dev/null

echo "$(date): Synced to GitHub" >> /home/z/my-project/hermes-home/sync.log
