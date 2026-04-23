#!/bin/bash
# GODMODE Auto-Initializer
# This script runs on every new Hermes session

HERMES_HOME="${HERMES_HOME:-/home/z/my-project/hermes-home}"
GODMODE_SCRIPT="$HERMES_HOME/skills/red-teaming/godmode/scripts/godmode_init.py"

# Set environment variables
export GODMODE_ENABLED=true
export GODMODE_MODEL="qwen/qwen3.5-122b-a10b"

# Load NVIDIA API key from .env if not set
if [ -z "$NVIDIA_API_KEY" ]; then
    if [ -f "$HERMES_HOME/.env" ]; then
        export NVIDIA_API_KEY=$(grep "^NVIDIA_API_KEY=" "$HERMES_HOME/.env" | cut -d'=' -f2)
    fi
fi

# Initialize godmode (silent - just sets up environment)
if [ -f "$GODMODE_SCRIPT" ]; then
    python3 "$GODMODE_SCRIPT" 2>/dev/null
fi

echo "[GODMODE] Initialized for Qwen 3.5 122B"
