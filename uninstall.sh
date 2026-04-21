#!/bin/bash
# ============================================================================
# Hermes Home - Uninstall Script
# ============================================================================
# Stops all Hermes processes and optionally removes the installation.
# Does NOT delete your GitHub repo or hermes-home data directory.
# ============================================================================

set -e

HERMES_HOME="$(cd "$(dirname "$0")" && pwd)"
HERMES_DIR="${HERMES_INSTALL_DIR:-$HOME/.hermes/hermes-agent}"

echo "Stopping Hermes processes..."

# Kill sync daemon
pkill -f "sync-daemon.sh" 2>/dev/null && echo "  ✓ Stopped sync daemon" || true

# Kill keeper
pkill -f "hermes-keeper" 2>/dev/null && echo "  ✓ Stopped keeper" || true

# Kill gateway
pkill -f "hermes gateway run" 2>/dev/null && echo "  ✓ Stopped gateway" || true

# Wait for processes to stop
sleep 2

echo ""
echo "All Hermes processes stopped."
echo ""
echo "Your data is preserved at: $HERMES_HOME"
echo "To fully remove Hermes:"
echo "  rm -rf $HERMES_DIR    # Remove agent code"
echo "  rm -rf $HERMES_HOME   # Remove all config & data (DESTRUCTIVE)"
echo ""
