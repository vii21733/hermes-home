#!/bin/bash
# Hermes Gateway Keeper - Single robust persistence script
# Uses flock for mutual exclusion, auto-restarts gateway on crash
# Designed to survive terminal disconnects and container restarts

# NO set -e or pipefail - we handle errors manually for robustness

# Configuration
HERMES_HOME="/home/z/my-project/hermes-home"
HERMES_DIR="/home/z/my-project/hermes-install"
HERMES_BIN="$HERMES_DIR/venv/bin/hermes"
LOG_DIR="$HERMES_HOME/logs"
LOCK_FILE="$HERMES_HOME/keeper.lock"
PID_FILE="$HERMES_HOME/keeper.pid"
LOG_FILE="$LOG_DIR/keeper.log"

# Environment
export HERMES_HOME="/home/z/my-project/hermes-home"
export UV_CACHE_DIR="/home/z/my-project/.uv-cache"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# Kill any stale hermes gateway processes (not keeper)
kill_stale_gateways() {
    local pids=""
    pids=$(pgrep -f "hermes gateway run" 2>/dev/null) || true
    if [ -n "$pids" ]; then
        log "Killing stale gateway processes: $pids"
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        sleep 5
        # Force kill any remaining
        pids=$(pgrep -f "hermes gateway run" 2>/dev/null) || true
        if [ -n "$pids" ]; then
            log "Force killing remaining gateways: $pids"
            echo "$pids" | xargs kill -9 2>/dev/null || true
            sleep 2
        fi
    fi
}

# Also kill stale daemon/watchdog from old setup
kill_stale_helpers() {
    local pids=""
    for pattern in "hermes-daemon.py" "hermes-watchdog.py" "ensure-hermes"; do
        pids=$(pgrep -f "$pattern" 2>/dev/null) || true
        if [ -n "$pids" ]; then
            log "Killing stale helper ($pattern): $pids"
            echo "$pids" | xargs kill -TERM 2>/dev/null || true
        fi
    done
}

# Trap signals - don't die, just log
trap 'log "Keeper received signal - ignoring (PID $$)"' SIGHUP SIGINT SIGTERM

# Main keeper function - runs inside flock
run_keeper() {
    log "=== Hermes Keeper Starting (PID $$) ==="
    
    # Write our PID
    echo $$ > "$PID_FILE" 2>/dev/null || true
    
    # Clean up any stale processes
    kill_stale_helpers
    kill_stale_gateways
    
    # Clean stale state files
    rm -f "$HERMES_HOME/gateway_state.json" "$HERMES_HOME/gateway.pid" "$HERMES_HOME/auth.lock" 2>/dev/null || true
    
    local restarts=0
    local backoff=5
    local last_start=0
    
    while true; do
        # Check if gateway is already running (shouldn't be, but safety check)
        if pgrep -f "hermes gateway run" > /dev/null 2>&1; then
            log "Gateway already running, waiting..."
            sleep 30
            continue
        fi
        
        # Clean state before start
        rm -f "$HERMES_HOME/gateway_state.json" "$HERMES_HOME/gateway.pid" "$HERMES_HOME/auth.lock" 2>/dev/null || true
        
        restarts=$((restarts + 1))
        log "Starting gateway (attempt $restarts)..."
        last_start=$(date +%s)
        
        # Start the gateway in background, redirect output to logs
        "$HERMES_BIN" gateway run \
            >> "$LOG_DIR/gateway-stdout.log" 2>> "$LOG_DIR/gateway-stderr.log" &
        local gpid=$!
        
        log "Gateway started (PID $gpid)"
        echo "$gpid" > "$HERMES_HOME/gateway-process.pid" 2>/dev/null || true
        
        # Wait for the gateway process - this blocks until it dies
        wait "$gpid" 2>/dev/null
        local exit_code=$?
        local now=$(date +%s)
        local uptime=$((now - last_start))
        
        log "Gateway died (exit code $exit_code, uptime ${uptime}s)"
        
        # If it ran for more than 60 seconds, reset backoff (it was stable)
        if [ "$uptime" -gt 60 ]; then
            backoff=5
            restarts=0
            log "Gateway was stable (${uptime}s), resetting backoff"
        else
            backoff=$((backoff * 2))
            if [ "$backoff" -gt 300 ]; then
                backoff=300
            fi
        fi
        
        log "Waiting ${backoff}s before restart..."
        sleep "$backoff"
    done
}

# Main entry point - acquire lock then run
main() {
    # Clean stale lock if the process is dead
    if [ -f "$PID_FILE" ]; then
        local old_pid=""
        old_pid=$(cat "$PID_FILE" 2>/dev/null) || true
        if [ -n "$old_pid" ] && ! kill -0 "$old_pid" 2>/dev/null; then
            log "Stale keeper PID $old_pid, removing lock"
            rm -f "$LOCK_FILE" "$PID_FILE" 2>/dev/null || true
        fi
    fi
    
    # Use flock for mutual exclusion - only ONE keeper can run at a time
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        echo "Another keeper is already running (lock held on $LOCK_FILE)" >&2
        exit 0
    fi
    
    # Keep the lock for the lifetime of this process
    log "Lock acquired on $LOCK_FILE"
    
    # Run the keeper loop
    run_keeper
}

main "$@"
