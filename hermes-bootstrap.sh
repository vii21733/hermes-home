#!/bin/bash
# Bootstrap script - starts the Python keeper + sync daemon
# Called from .bashrc or manually on container restart

HERMES_HOME="/home/z/my-project/hermes-home"
KEEPER="$HERMES_HOME/hermes-keeper.py"
PYTHON="/home/z/my-project/hermes-install/venv/bin/python3"
LOG_DIR="$HERMES_HOME/logs"
LOG_FILE="$LOG_DIR/bootstrap.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# ── Restore Git Credentials (survives container restarts) ────────────────
CREDENTIALS_FILE="$HOME/.git-credentials"
BACKUP_CREDENTIALS="$HERMES_HOME/.git-credentials-backup"

if [ ! -f "$CREDENTIALS_FILE" ] || ! grep -q "github.com" "$CREDENTIALS_FILE" 2>/dev/null; then
    if [ -f "$BACKUP_CREDENTIALS" ]; then
        cp "$BACKUP_CREDENTIALS" "$CREDENTIALS_FILE"
        chmod 600 "$CREDENTIALS_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restored git credentials from backup" >> "$LOG_FILE"
    fi
fi
git config --global credential.helper store 2>/dev/null

# ── Start Keeper (gateway auto-restart) ──────────────────────────────────
KEEPER_STARTED=false
if [ -f "$HERMES_HOME/keeper.pid" ]; then
    KP=$(cat "$HERMES_HOME/keeper.pid" 2>/dev/null || true)
    if [ -n "$KP" ] && kill -0 "$KP" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Keeper already running (PID $KP)" >> "$LOG_FILE"
        KEEPER_STARTED=true
    fi
fi

if [ "$KEEPER_STARTED" = false ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting keeper..." >> "$LOG_FILE"
    "$PYTHON" "$KEEPER" >> "$LOG_FILE" 2>&1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Keeper launched" >> "$LOG_FILE"
fi

# ── Start Sync Daemon (GitHub auto-backup) ───────────────────────────────
SYNC_STARTED=false
if [ -f "$HERMES_HOME/sync-daemon.pid" ]; then
    SP=$(cat "$HERMES_HOME/sync-daemon.pid" 2>/dev/null || true)
    if [ -n "$SP" ] && kill -0 "$SP" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync daemon already running (PID $SP)" >> "$LOG_FILE"
        SYNC_STARTED=true
    fi
fi

if [ "$SYNC_STARTED" = false ]; then
    python3 "$HERMES_HOME/sync-daemon.py" >> "$LOG_FILE" 2>&1 &
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync daemon started" >> "$LOG_FILE"
fi
