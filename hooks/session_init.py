#!/usr/bin/env python3
"""
GODMODE Session Initialization Hook
This script runs on every new Hermes session to initialize godmode.
"""
import os
import sys

HERMES_HOME = os.environ.get("HERMES_HOME", "/home/z/my-project/hermes-home")
GODMODE_SCRIPT = os.path.join(HERMES_HOME, "skills/red-teaming/godmode/scripts/godmode_qwen.py")

def init_godmode():
    """Initialize godmode for the session"""
    
    # Set environment variables
    os.environ["GODMODE_ENABLED"] = "true"
    os.environ["GODMODE_MODEL"] = "qwen/qwen3.5-122b-a10b"
    
    # Check if NVIDIA API key exists
    api_key = os.environ.get("NVIDIA_API_KEY", "")
    if not api_key:
        # Try to load from .env
        env_file = os.path.join(HERMES_HOME, ".env")
        if os.path.exists(env_file):
            with open(env_file, 'r') as f:
                for line in f:
                    if line.startswith("NVIDIA_API_KEY="):
                        api_key = line.strip().split("=", 1)[1]
                        os.environ["NVIDIA_API_KEY"] = api_key
                        break
    
    return {
        "status": "initialized",
        "model": "qwen/qwen3.5-122b-a10b",
        "api_key_set": bool(api_key),
        "script_exists": os.path.exists(GODMODE_SCRIPT)
    }

if __name__ == "__main__":
    result = init_godmode()
    print(f"GODMODE: {result}")
