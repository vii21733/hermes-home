#!/bin/bash
# ============================================================================
# Hermes Home - Full Auto-Install & Restore
# ============================================================================
# Usage:
#   git clone https://github.com/vii21733/hermes-home.git
#   cd hermes-home
#   bash setup.sh
#
# This script:
#   1. Installs system dependencies (Python 3.11+, Node.js 22+, git)
#   2. Clones and installs Hermes Agent from GitHub
#   3. Restores all your hermes-home config, data, and state
#   4. Starts the gateway and keeper
#   5. Sets up auto-sync to GitHub every 30 minutes
# ============================================================================

set -e

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Configuration ───────────────────────────────────────────────────────────
HERMES_HOME="$(cd "$(dirname "$0")" && pwd)"
HERMES_DIR="${HERMES_INSTALL_DIR:-$HOME/.hermes/hermes-agent}"
HERMES_BIN="$HERMES_DIR/venv/bin/hermes"
PYTHON_VERSION="3.11"
NODE_VERSION="22"
HERMES_REPO="https://github.com/NousResearch/hermes-agent.git"
GITHUB_REPO="https://github.com/vii21733/hermes-home.git"

echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║          🏠 Hermes Home - Auto Install & Restore         ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: System Dependencies ────────────────────────────────────────────
echo -e "${BLUE}${BOLD}[1/6] Checking system dependencies...${NC}"

check_command() {
    if command -v "$1" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 ($($1 --version 2>/dev/null | head -1))"
        return 0
    else
        return 1
    fi
}

install_python() {
    echo -e "  ${YELLOW}Installing Python 3...${NC}"
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq python3 python3-pip python3-venv
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3 python3-pip python3-devel
    elif command -v brew &>/dev/null; then
        brew install python@3.11
    elif command -v apk &>/dev/null; then
        sudo apk add python3 python3-dev py3-pip
    elif command -v pkg &>/dev/null; then
        pkg install python python-pip
    else
        echo -e "  ${RED}Cannot auto-install Python. Please install Python 3.11+ manually.${NC}"
        exit 1
    fi
}

install_node() {
    echo -e "  ${YELLOW}Installing Node.js...${NC}"
    if command -v apt-get &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null
        sudo apt-get install -y -qq nodejs
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y nodejs
    elif command -v brew &>/dev/null; then
        brew install node@22
    elif command -v apk &>/dev/null; then
        sudo apk add nodejs npm
    elif command -v pkg &>/dev/null; then
        pkg install nodejs
    else
        echo -e "  ${RED}Cannot auto-install Node.js. Please install Node.js 22+ manually.${NC}"
        exit 1
    fi
}

install_git() {
    echo -e "  ${YELLOW}Installing git...${NC}"
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq git
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git
    elif command -v brew &>/dev/null; then
        brew install git
    elif command -v apk &>/dev/null; then
        sudo apk add git
    elif command -v pkg &>/dev/null; then
        pkg install git
    else
        echo -e "  ${RED}Cannot auto-install git. Please install git manually.${NC}"
        exit 1
    fi
}

check_command python3 || install_python
check_command node || install_node
check_command git || install_git
check_command curl

echo -e "  ${GREEN}All system dependencies ready!${NC}"
echo ""

# ── Step 2: Clone & Install Hermes Agent ────────────────────────────────────
echo -e "${BLUE}${BOLD}[2/6] Installing Hermes Agent...${NC}"

if [ -d "$HERMES_DIR" ] && [ -f "$HERMES_BIN" ]; then
    echo -e "  ${GREEN}✓${NC} Hermes Agent already installed at $HERMES_DIR"
else
    echo -e "  ${YELLOW}Cloning Hermes Agent from GitHub...${NC}"
    mkdir -p "$(dirname "$HERMES_DIR")"
    git clone --depth 1 "$HERMES_REPO" "$HERMES_DIR"

    echo -e "  ${YELLOW}Creating Python virtual environment...${NC}"
    cd "$HERMES_DIR"
    python3 -m venv venv
    source venv/bin/activate

    echo -e "  ${YELLOW}Installing Hermes Agent (this may take a few minutes)...${NC}"
    pip install --upgrade pip --quiet
    pip install -e ".[all]" --quiet 2>/dev/null || pip install -e . --quiet
    deactivate

    echo -e "  ${GREEN}✓${NC} Hermes Agent installed!"
fi
echo ""

# ── Step 3: Restore Config & Data ──────────────────────────────────────────
echo -e "${BLUE}${BOLD}[3/6] Restoring Hermes Home configuration...${NC}"

# Set HERMES_HOME environment variable
export HERMES_HOME="$HERMES_HOME"

# Create necessary directories
mkdir -p "$HERMES_HOME/logs"
mkdir -p "$HERMES_HOME/cache"
mkdir -p "$HERMES_HOME/audio_cache"
mkdir -p "$HERMES_HOME/image_cache"
mkdir -p "$HERMES_HOME/sessions"
mkdir -p "$HERMES_HOME/sandboxes"
mkdir -p "$HERMES_HOME/cron"
mkdir -p "$HERMES_HOME/hooks"
mkdir -p "$HERMES_HOME/memories"
mkdir -p "$HERMES_HOME/skills"
mkdir -p "$HERMES_HOME/home"

# Verify key files exist
KEY_FILES=(".env" "config.yaml" "prefill.json" "SOUL.md" "auth.json")
for f in "${KEY_FILES[@]}"; do
    if [ -f "$HERMES_HOME/$f" ]; then
        echo -e "  ${GREEN}✓${NC} $f"
    else
        echo -e "  ${YELLOW}⚠${NC} $f not found (you may need to configure it)"
    fi
done

# Verify state database
if [ -f "$HERMES_HOME/state.db" ]; then
    echo -e "  ${GREEN}✓${NC} state.db ($(du -sh "$HERMES_HOME/state.db" | cut -f1))"
else
    echo -e "  ${YELLOW}⚠${NC} state.db not found (will be created on first run)"
fi

echo -e "  ${GREEN}Configuration restored!${NC}"
echo ""

# ── Step 4: Update Keeper Scripts for New Paths ────────────────────────────
echo -e "${BLUE}${BOLD}[4/6] Updating scripts for this machine...${NC}"

# Update hermes-keeper.py paths
if [ -f "$HERMES_HOME/hermes-keeper.py" ]; then
    sed -i.bak \
        -e "s|HERMES_HOME = \".*\"|HERMES_HOME = \"$HERMES_HOME\"|g" \
        -e "s|HERMES_DIR = \".*\"|HERMES_DIR = \"$HERMES_DIR\"|g" \
        "$HERMES_HOME/hermes-keeper.py"
    echo -e "  ${GREEN}✓${NC} Updated hermes-keeper.py paths"
fi

# Update hermes-keeper.sh paths
if [ -f "$HERMES_HOME/hermes-keeper.sh" ]; then
    sed -i.bak \
        -e "s|HERMES_HOME=.*|HERMES_HOME=\"$HERMES_HOME\"|g" \
        -e "s|HERMES_DIR=.*|HERMES_DIR=\"$HERMES_DIR\"|g" \
        "$HERMES_HOME/hermes-keeper.sh"
    echo -e "  ${GREEN}✓${NC} Updated hermes-keeper.sh paths"
fi

# Update hermes-bootstrap.sh paths
if [ -f "$HERMES_HOME/hermes-bootstrap.sh" ]; then
    sed -i.bak \
        -e "s|HERMES_HOME=.*|HERMES_HOME=\"$HERMES_HOME\"|g" \
        -e "s|PYTHON=.*|PYTHON=\"$HERMES_DIR/venv/bin/python3\"|g" \
        "$HERMES_HOME/hermes-bootstrap.sh"
    echo -e "  ${GREEN}✓${NC} Updated hermes-bootstrap.sh paths"
fi

# Update auto-sync.sh paths
if [ -f "$HERMES_HOME/auto-sync.sh" ]; then
    sed -i.bak \
        -e "s|cd .*|cd \"$HERMES_HOME\" || exit 1|g" \
        "$HERMES_HOME/auto-sync.sh"
    echo -e "  ${GREEN}✓${NC} Updated auto-sync.sh paths"
fi

# Update sync-daemon.sh paths
if [ -f "$HERMES_HOME/sync-daemon.sh" ]; then
    sed -i.bak \
        -e "s|/home/z/my-project/hermes-home/auto-sync.sh|\"$HERMES_HOME/auto-sync.sh\"|g" \
        "$HERMES_HOME/sync-daemon.sh"
    echo -e "  ${GREEN}✓${NC} Updated sync-daemon.sh paths"
fi

echo ""

# ── Step 5: Start Hermes Gateway ───────────────────────────────────────────
echo -e "${BLUE}${BOLD}[5/6] Starting Hermes Gateway...${NC}"

# Set environment
export HERMES_HOME="$HERMES_HOME"

# Start via keeper (which handles auto-restart)
cd "$HERMES_DIR"
"$HERMES_DIR/venv/bin/python3" "$HERMES_HOME/hermes-keeper.py" &

sleep 5

# Check if gateway started
if pgrep -f "hermes gateway run" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Gateway is running!"
else
    echo -e "  ${YELLOW}⚠ Gateway may still be starting... check logs with:${NC}"
    echo -e "    tail -f $HERMES_HOME/logs/agent.log"
fi
echo ""

# ── Step 6: Auto-Sync Setup ────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}[6/6] Setting up auto-sync to GitHub (every 30 min)...${NC}"

# Initialize git if not already
if [ ! -d "$HERMES_HOME/.git" ]; then
    cd "$HERMES_HOME"
    git init
    git branch -m main
    git remote add origin "$GITHUB_REPO"
    git config user.name "vii21733"
    git config user.email "vii21733@users.noreply.github.com"
    echo -e "  ${GREEN}✓${NC} Git initialized"
fi

# Start sync daemon in background
nohup "$HERMES_HOME/sync-daemon.sh" > /dev/null 2>&1 &
SYNC_PID=$!
echo -e "  ${GREEN}✓${NC} Auto-sync daemon started (PID $SYNC_PID)"
echo -e "  ${GREEN}✓${NC} Files will sync to GitHub every 30 minutes"
echo ""

# ── Add bootstrap to shell rc ──────────────────────────────────────────────
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ] && [ "$SHELL" = "/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

BOOTSTRAP_LINE="bash $HERMES_HOME/hermes-bootstrap.sh 2>/dev/null"
if ! grep -q "hermes-bootstrap" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Auto-start Hermes on shell login" >> "$SHELL_RC"
    echo "$BOOTSTRAP_LINE" >> "$SHELL_RC"
    echo -e "  ${GREEN}✓${NC} Added auto-start to $SHELL_RC"
else
    echo -e "  ${GREEN}✓${NC} Auto-start already in $SHELL_RC"
fi

# ── Done! ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              ✅ Hermes Home is Ready!                     ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Key locations:${NC}"
echo -e "    Config:     $HERMES_HOME/config.yaml"
echo -e "    Agent:      $HERMES_DIR"
echo -e "    Logs:       $HERMES_HOME/logs/"
echo -e "    Sessions:   $HERMES_HOME/sessions/"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo -e "    hermes                  - Start interactive CLI"
echo -e "    hermes gateway status   - Check gateway status"
echo -e "    hermes gateway restart  - Restart gateway"
echo -e "    tail -f $HERMES_HOME/logs/agent.log  - Watch logs"
echo ""
echo -e "  ${BOLD}GitHub backup:${NC}"
echo -e "    Repo:  https://github.com/vii21733/hermes-home"
echo -e "    Sync:  Every 30 minutes (auto)"
echo ""
