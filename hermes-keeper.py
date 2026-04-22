#!/usr/bin/env python3
"""
Hermes Gateway Keeper - A robust, self-daemonizing Python process manager.
Uses double-fork to fully detach from the parent process group,
ensuring survival when the launching shell/tool exits.
"""
import os, sys, time, signal, subprocess, pathlib, json

HERMES_HOME = "/home/z/my-project/hermes-home"
HERMES_DIR = "/home/z/my-project/hermes-install"
HERMES_BIN = f"{HERMES_DIR}/venv/bin/hermes"
LOG_DIR = f"{HERMES_HOME}/logs"
PID_FILE = f"{HERMES_HOME}/keeper.pid"
LOCK_FILE = f"{HERMES_HOME}/keeper.lock"
STATE_FILE = f"{HERMES_HOME}/keeper-state.json"

os.environ["HERMES_HOME"] = HERMES_HOME
os.environ["UV_CACHE_DIR"] = "/home/z/my-project/.uv-cache"

pathlib.Path(LOG_DIR).mkdir(parents=True, exist_ok=True)

def log(msg):
    with open(f"{LOG_DIR}/keeper.log", "a") as f:
        f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")

def write_state(status, gpid=None, restarts=0):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump({"status": status, "keeper_pid": os.getpid(), "gateway_pid": gpid,
                        "restarts": restarts, "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S")}, f, indent=2)
    except: pass

def is_pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except: return False

def kill_stale_processes():
    my_pid = os.getpid()
    for pattern in ["hermes gateway run", "hermes-keeper"]:
        try:
            r = subprocess.run(["pgrep", "-f", pattern], capture_output=True, text=True, timeout=5)
            for p in (r.stdout.strip().split('\n') if r.stdout.strip() else []):
                pid = int(p.strip())
                if pid != my_pid and pid != os.getppid():
                    log(f"Killing stale (PID {pid}, pattern: {pattern})")
                    try: os.kill(pid, signal.SIGTERM)
                    except: pass
            time.sleep(2)
        except: pass

def daemonize():
    if os.fork() > 0: os._exit(0)
    os.setsid()
    if os.fork() > 0: os._exit(0)
    os.chdir("/")
    sys.stdout.flush()
    sys.stderr.flush()

def start_gateway():
    for f in ["gateway_state.json", "gateway.pid", "auth.lock"]:
        pathlib.Path(f"{HERMES_HOME}/{f}").unlink(missing_ok=True)
    
    env = os.environ.copy()
    env["HERMES_HOME"] = HERMES_HOME
    env["UV_CACHE_DIR"] = "/home/z/my-project/.uv-cache"
    
    stdout_log = open(f"{LOG_DIR}/gateway-stdout.log", "a")
    stderr_log = open(f"{LOG_DIR}/gateway-stderr.log", "a")
    
    proc = subprocess.Popen(
        [HERMES_BIN, "gateway", "run"],
        cwd=HERMES_DIR, env=env,
        stdin=subprocess.DEVNULL, stdout=stdout_log, stderr=stderr_log,
        start_new_session=True,
    )
    return proc

def run_keeper():
    log(f"=== Hermes Keeper Starting (PID {os.getpid()}) ===")
    write_state("starting")
    kill_stale_processes()
    
    # Write PID file
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    
    proc = start_gateway()
    log(f"Gateway started (PID {proc.pid})")
    write_state("running", gpid=proc.pid)
    
    restarts = 0
    MAX_RESTARTS = 50
    
    while restarts < MAX_RESTARTS:
        proc.wait()
        exit_code = proc.returncode
        log(f"Gateway died (exit code {exit_code}), restart #{restarts + 1}")
        
        # Check for telegram flood control - wait longer
        try:
            with open(f"{LOG_DIR}/gateway-stderr.log", "r") as f:
                tail = f.read()[-2000:]
            if "flood control" in tail.lower():
                wait = 180
                log(f"Flood control detected, waiting {wait}s")
                write_state("flood_wait", gpid=proc.pid, restarts=restarts)
                time.sleep(wait)
        except: pass
        
        # Exponential backoff: 5s, 10s, 20s, 40s, max 120s
        wait = min(5 * (2 ** min(restarts, 5)), 120)
        restarts += 1
        write_state("restarting", gpid=proc.pid, restarts=restarts)
        time.sleep(wait)
        
        # Clean stale files before restart
        for f in ["gateway_state.json", "gateway.pid", "auth.lock"]:
            pathlib.Path(f"{HERMES_HOME}/{f}").unlink(missing_ok=True)
        
        proc = start_gateway()
        log(f"Gateway restarted (PID {proc.pid})")
        write_state("running", gpid=proc.pid, restarts=restarts)
        
        # Wait for stability
        time.sleep(10)
        if proc.poll() is None:
            log("Gateway stable, resetting backoff")
            restarts = 0
    
    log("Max restarts reached, giving up")
    write_state("dead", restarts=restarts)

if __name__ == "__main__":
    daemonize()
    try:
        run_keeper()
    except Exception as e:
        log(f"Keeper crashed: {e}")
        write_state("crashed")
