#!/usr/bin/env python3
"""
Hermes Home Auto-Sync Daemon
Syncs to GitHub every 60 seconds. Uses double-fork to survive parent exit.
"""
import os, sys, time, subprocess, pathlib

HERMES_HOME = "/home/z/my-project/hermes-home"
SYNC_SCRIPT = f"{HERMES_HOME}/auto-sync.sh"
PID_FILE = f"{HERMES_HOME}/sync-daemon.pid"
LOG_FILE = f"{HERMES_HOME}/sync.log"
INTERVAL = 60

def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except:
        pass

def daemonize():
    """Double-fork to fully detach from parent process group."""
    if os.fork() > 0:
        os._exit(0)
    os.setsid()
    if os.fork() > 0:
        os._exit(0)
    os.chdir("/")
    sys.stdout.flush()
    sys.stderr.flush()

def main():
    daemonize()
    
    # Write PID
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    
    log(f"Sync daemon started (PID {os.getpid()}, interval {INTERVAL}s)")
    
    while True:
        time.sleep(INTERVAL)
        try:
            result = subprocess.run(
                ["bash", SYNC_SCRIPT],
                capture_output=True, text=True, timeout=30,
                cwd=HERMES_HOME
            )
            if result.returncode != 0:
                log(f"Sync failed: {result.stderr[:200]}")
        except Exception as e:
            log(f"Sync error: {e}")

if __name__ == "__main__":
    main()
