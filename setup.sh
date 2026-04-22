#!/bin/bash
# ============================================================================
# Hermes Home - Full Auto-Install & Restore
# ============================================================================
# Usage:
#   git clone https://github.com/vii21733/hermes-home.git
#   cd hermes-home
#   bash setup.sh
#
# Supported OS:
#   - Linux: Ubuntu, Debian, Fedora, RHEL, CentOS, Arch, Manjaro, Alpine,
#            OpenSUSE, Gentoo, Solus, NixOS, Void, Clear Linux
#   - macOS: Intel & Apple Silicon (Homebrew)
#   - Windows: Via WSL2 (auto-detected and guided)
#   - Android: Termux
#   - FreeBSD
#   - ChromeOS (Crostini/Linux container)
#
# This script:
#   1. Detects OS and installs system dependencies
#   2. Clones and installs Hermes Agent from GitHub
#   3. Restores all your hermes-home config, data, and state
#   4. Starts the gateway and keeper
#   5. Sets up auto-sync to GitHub every 1 minute
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
GITHUB_TOKEN="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"
GITHUB_AUTH_REPO="https://vii21733:${GITHUB_TOKEN}@github.com/vii21733/hermes-home.git"
SYNC_INTERVAL=60  # 1 minute in seconds

echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║          Hermes Home - Auto Install & Restore            ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── OS Detection ────────────────────────────────────────────────────────────
detect_os() {
    # Check for WSL first (Windows Subsystem for Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
        return
    fi

    # Check for Termux (Android)
    if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
        echo "termux"
        return
    fi

    # Check for FreeBSD
    if [ "$(uname -s)" = "FreeBSD" ]; then
        echo "freebsd"
        return
    fi

    # Check for macOS
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "macos"
        return
    fi

    # Linux distro detection
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|linuxmint|pop|elementary|zorin|neon|kde_neon|parrot|kali|deepin)
                echo "ubuntu" ;;
            debian|devuan|raspbian)
                echo "debian" ;;
            fedora|nobara)
                echo "fedora" ;;
            rhel|centos|rocky|alma|ol|amzn)
                echo "rhel" ;;
            arch|manjaro|endeavouros|garuda|artix|arco)
                echo "arch" ;;
            alpine)
                echo "alpine" ;;
            opensuse*|sles)
                echo "opensuse" ;;
            gentoo|funtoo)
                echo "gentoo" ;;
            solus)
                echo "solus" ;;
            void)
                echo "void" ;;
            nixos)
                echo "nixos" ;;
            clear-linux-os)
                echo "clear" ;;
            *)
                echo "linux-unknown" ;;
        esac
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/gentoo-release ]; then
        echo "gentoo"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo -e "  Detected OS: ${BOLD}$OS${NC}"
echo ""

# ── Step 1: System Dependencies ────────────────────────────────────────────
echo -e "${BLUE}${BOLD}[1/6] Checking system dependencies...${NC}"

check_command() {
    if command -v "$1" &>/dev/null; then
        local ver
        ver=$($1 --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}OK${NC} $1 (${ver:-installed})"
        return 0
    else
        return 1
    fi
}

install_python() {
    echo -e "  ${YELLOW}Installing Python 3...${NC}"
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update -qq
            sudo apt-get install -y -qq python3 python3-pip python3-venv
            ;;
        fedora)
            sudo dnf install -y python3 python3-pip python3-devel
            ;;
        rhel)
            sudo yum install -y python3 python3-pip python3-devel
            ;;
        arch|manjaro|endeavouros|garuda|artix|arco)
            sudo pacman -Sy --noconfirm python python-pip
            ;;
        alpine)
            sudo apk add python3 python3-dev py3-pip
            ;;
        opensuse)
            sudo zypper install -y python3 python3-pip python3-devel
            ;;
        gentoo)
            sudo emerge -q dev-lang/python
            ;;
        solus)
            sudo eopkg install -y python3
            ;;
        void)
            sudo xbps-install -y python3 python3-pip python3-devel
            ;;
        nixos)
            nix-env -iA nixpkgs.python3 nixpkgs.python3Packages.pip
            ;;
        clear)
            sudo swupd bundle-add python3-basic
            ;;
        macos)
            brew install python@3.11
            ;;
        freebsd)
            sudo pkg install -y python3 py311-pip
            ;;
        termux)
            pkg install python python-pip
            ;;
        wsl)
            sudo apt-get update -qq
            sudo apt-get install -y -qq python3 python3-pip python3-venv
            ;;
        *)
            echo -e "  ${RED}Cannot auto-install Python. Please install Python 3.11+ manually.${NC}"
            echo -e "  Download from: https://www.python.org/downloads/"
            exit 1
            ;;
    esac
}

install_node() {
    echo -e "  ${YELLOW}Installing Node.js...${NC}"
    case "$OS" in
        ubuntu|debian|wsl)
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null || true
            sudo apt-get install -y -qq nodejs
            ;;
        fedora)
            sudo dnf install -y nodejs
            ;;
        rhel)
            curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - 2>/dev/null || true
            sudo yum install -y nodejs
            ;;
        arch|manjaro|endeavouros|garuda|artix|arco)
            sudo pacman -Sy --noconfirm nodejs npm
            ;;
        alpine)
            sudo apk add nodejs npm
            ;;
        opensuse)
            sudo zypper install -y nodejs npm
            ;;
        gentoo)
            sudo emerge -q net-libs/nodejs
            ;;
        solus)
            sudo eopkg install -y nodejs
            ;;
        void)
            sudo xbps-install -y nodejs
            ;;
        nixos)
            nix-env -iA nixpkgs.nodejs
            ;;
        clear)
            sudo swupd bundle-add nodejs-basic
            ;;
        macos)
            brew install node@22
            ;;
        freebsd)
            sudo pkg install -y node npm
            ;;
        termux)
            pkg install nodejs
            ;;
        *)
            echo -e "  ${RED}Cannot auto-install Node.js. Please install Node.js 22+ manually.${NC}"
            echo -e "  Download from: https://nodejs.org/"
            exit 1
            ;;
    esac
}

install_git() {
    echo -e "  ${YELLOW}Installing git...${NC}"
    case "$OS" in
        ubuntu|debian|wsl)
            sudo apt-get install -y -qq git
            ;;
        fedora)
            sudo dnf install -y git
            ;;
        rhel)
            sudo yum install -y git
            ;;
        arch|manjaro|endeavouros|garuda|artix|arco)
            sudo pacman -Sy --noconfirm git
            ;;
        alpine)
            sudo apk add git
            ;;
        opensuse)
            sudo zypper install -y git
            ;;
        gentoo)
            sudo emerge -q dev-vcs/git
            ;;
        solus)
            sudo eopkg install -y git
            ;;
        void)
            sudo xbps-install -y git
            ;;
        nixos)
            nix-env -iA nixpkgs.git
            ;;
        clear)
            sudo swupd bundle-add git
            ;;
        macos)
            brew install git
            ;;
        freebsd)
            sudo pkg install -y git
            ;;
        termux)
            pkg install git
            ;;
        *)
            echo -e "  ${RED}Cannot auto-install git. Please install git manually.${NC}"
            exit 1
            ;;
    esac
}

install_build_deps() {
    echo -e "  ${YELLOW}Installing build dependencies...${NC}"
    case "$OS" in
        ubuntu|debian|wsl)
            sudo apt-get install -y -qq build-essential python3-dev libffi-dev libssl-dev 2>/dev/null || true
            ;;
        fedora)
            sudo dnf install -y gcc gcc-c++ python3-devel libffi-devel openssl-devel 2>/dev/null || true
            ;;
        rhel)
            sudo yum install -y gcc gcc-c++ python3-devel libffi-devel openssl-devel 2>/dev/null || true
            ;;
        arch|manjaro|endeavouros|garuda|artix|arco)
            sudo pacman -Sy --noconfirm base-devel python-setuptools 2>/dev/null || true
            ;;
        alpine)
            sudo apk add build-base python3-dev libffi-dev openssl-dev 2>/dev/null || true
            ;;
        opensuse)
            sudo zypper install -y gcc gcc-c++ python3-devel libffi-devel openssl-devel 2>/dev/null || true
            ;;
        freebsd)
            sudo pkg install -y gcc py311-setuptools 2>/dev/null || true
            ;;
        termux)
            pkg install build-setup python-dev 2>/dev/null || true
            ;;
    esac
}

check_command python3 || install_python
check_command node || install_node
check_command git || install_git
check_command curl || { echo -e "  ${YELLOW}Installing curl...${NC}"; case "$OS" in ubuntu|debian|wsl) sudo apt-get install -y -qq curl;; alpine) sudo apk add curl;; arch*) sudo pacman -Sy --noconfirm curl;; macos) brew install curl;; termux) pkg install curl;; freebsd) sudo pkg install -y curl;; esac; }
install_build_deps

echo -e "  ${GREEN}All system dependencies ready!${NC}"
echo ""

# ── Windows WSL Check ──────────────────────────────────────────────────────
if [ "$OS" = "wsl" ]; then
    echo -e "${YELLOW}${BOLD}Windows WSL2 detected!${NC}"
    echo -e "  Hermes will run inside WSL. To access from Windows:"
    echo -e "  - Telegram bot works directly (no extra setup needed)"
    echo -e "  - For CLI, open WSL terminal (wsl command in PowerShell)"
    echo ""
fi

# ── Step 2: Clone & Install Hermes Agent ────────────────────────────────────
echo -e "${BLUE}${BOLD}[2/6] Installing Hermes Agent...${NC}"

if [ -d "$HERMES_DIR" ] && [ -f "$HERMES_BIN" ]; then
    echo -e "  ${GREEN}OK${NC} Hermes Agent already installed at $HERMES_DIR"
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

    echo -e "  ${GREEN}OK${NC} Hermes Agent installed!"
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
        echo -e "  ${GREEN}OK${NC} $f"
    else
        echo -e "  ${YELLOW}!!${NC} $f not found (you may need to configure it)"
    fi
done

# Verify state database
if [ -f "$HERMES_HOME/state.db" ]; then
    echo -e "  ${GREEN}OK${NC} state.db ($(du -sh "$HERMES_HOME/state.db" | cut -f1))"
else
    echo -e "  ${YELLOW}!!${NC} state.db not found (will be created on first run)"
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
    echo -e "  ${GREEN}OK${NC} Updated hermes-keeper.py paths"
fi

# Update hermes-keeper.sh paths
if [ -f "$HERMES_HOME/hermes-keeper.sh" ]; then
    sed -i.bak \
        -e "s|HERMES_HOME=.*|HERMES_HOME=\"$HERMES_HOME\"|g" \
        -e "s|HERMES_DIR=.*|HERMES_DIR=\"$HERMES_DIR\"|g" \
        "$HERMES_HOME/hermes-keeper.sh"
    echo -e "  ${GREEN}OK${NC} Updated hermes-keeper.sh paths"
fi

# Update hermes-bootstrap.sh paths
if [ -f "$HERMES_HOME/hermes-bootstrap.sh" ]; then
    sed -i.bak \
        -e "s|HERMES_HOME=.*|HERMES_HOME=\"$HERMES_HOME\"|g" \
        -e "s|PYTHON=.*|PYTHON=\"$HERMES_DIR/venv/bin/python3\"|g" \
        "$HERMES_HOME/hermes-bootstrap.sh"
    echo -e "  ${GREEN}OK${NC} Updated hermes-bootstrap.sh paths"
fi

# Update auto-sync.sh paths
if [ -f "$HERMES_HOME/auto-sync.sh" ]; then
    sed -i.bak \
        -e "s|cd .*|cd \"$HERMES_HOME\" || exit 1|g" \
        "$HERMES_HOME/auto-sync.sh"
    echo -e "  ${GREEN}OK${NC} Updated auto-sync.sh paths"
fi

# Update sync-daemon.sh paths and interval
if [ -f "$HERMES_HOME/sync-daemon.sh" ]; then
    sed -i.bak \
        -e "s|/home/z/my-project/hermes-home/auto-sync.sh|\"$HERMES_HOME/auto-sync.sh\"|g" \
        -e "s|INTERVAL=.*|INTERVAL=$SYNC_INTERVAL|g" \
        "$HERMES_HOME/sync-daemon.sh"
    echo -e "  ${GREEN}OK${NC} Updated sync-daemon.sh (1 min interval)"
fi

# Update sync-daemon.py paths
if [ -f "$HERMES_HOME/sync-daemon.py" ]; then
    sed -i.bak \
        -e "s|HERMES_HOME = \".*\"|HERMES_HOME = \"$HERMES_HOME\"|g" \
        "$HERMES_HOME/sync-daemon.py"
    echo -e "  ${GREEN}OK${NC} Updated sync-daemon.py paths"
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
    echo -e "  ${GREEN}OK${NC} Gateway is running!"
else
    echo -e "  ${YELLOW}!! Gateway may still be starting... check logs with:${NC}"
    echo -e "    tail -f $HERMES_HOME/logs/agent.log"
fi
echo ""

# ── Step 6: Auto-Sync Setup ────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}[6/6] Setting up auto-sync to GitHub (every 1 min)...${NC}"

# Configure git remote with auth token
if [ -d "$HERMES_HOME/.git" ]; then
    # Already a git repo (cloned from GitHub) - update remote URL with token
    cd "$HERMES_HOME"
    git remote set-url origin "$GITHUB_AUTH_REPO" 2>/dev/null || git remote add origin "$GITHUB_AUTH_REPO"
    echo -e "  ${GREEN}OK${NC} Git remote configured with auth"
else
    # Fresh directory - init and set up
    cd "$HERMES_HOME"
    git init
    git branch -m main
    git remote add origin "$GITHUB_AUTH_REPO"
    echo -e "  ${GREEN}OK${NC} Git initialized with auth"
fi
git config user.name "vii21733"
git config user.email "vii21733@users.noreply.github.com"

# Start sync daemon in background (Python version for reliability)
if [ -f "$HERMES_HOME/sync-daemon.py" ]; then
    nohup python3 "$HERMES_HOME/sync-daemon.py" > /dev/null 2>&1 &
    SYNC_PID=$!
    echo -e "  ${GREEN}OK${NC} Auto-sync daemon started (PID $SYNC_PID) [Python]"
else
    nohup "$HERMES_HOME/sync-daemon.sh" > /dev/null 2>&1 &
    SYNC_PID=$!
    echo -e "  ${GREEN}OK${NC} Auto-sync daemon started (PID $SYNC_PID) [Bash]"
fi
echo -e "  ${GREEN}OK${NC} Files will auto-push to GitHub every 1 minute"
echo ""

# ── Add bootstrap to shell rc ──────────────────────────────────────────────
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ] && [ "$SHELL" = "/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ] && [ "$(uname -s)" = "Darwin" ]; then
    SHELL_RC="$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then
    SHELL_RC="$HOME/.profile"
fi

BOOTSTRAP_LINE="bash $HERMES_HOME/hermes-bootstrap.sh 2>/dev/null"
if ! grep -q "hermes-bootstrap" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Auto-start Hermes on shell login" >> "$SHELL_RC"
    echo "$BOOTSTRAP_LINE" >> "$SHELL_RC"
    echo -e "  ${GREEN}OK${NC} Added auto-start to $SHELL_RC"
else
    echo -e "  ${GREEN}OK${NC} Auto-start already in $SHELL_RC"
fi

# ── Set HERMES_HOME persistently ──────────────────────────────────────────
if ! grep -q "HERMES_HOME" "$SHELL_RC" 2>/dev/null; then
    echo "export HERMES_HOME=\"$HERMES_HOME\"" >> "$SHELL_RC"
    echo -e "  ${GREEN}OK${NC} Added HERMES_HOME to $SHELL_RC"
fi

# ── Done! ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              Hermes Home is Ready!                       ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}OS Detected:${NC}     $OS"
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
echo -e "    Sync:  Every 1 minute (auto)"
echo ""
