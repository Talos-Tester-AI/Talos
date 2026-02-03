#!/bin/bash

# Talos Install & Run Script
# Works on Linux and macOS

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. OS Detection
OS="$(uname -s)"
case "${OS}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${OS}"
esac

echo_info "Detected OS: $machine"

if [ "$machine" == "UNKNOWN:${OS}" ]; then
    echo_error "Unsupported operating system: $OS"
    exit 1
fi

# 2. Prerequisite Checks
echo_info "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo_error "Node.js is not installed. Please install Node.js (v18+ recommended)."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo_error "Python 3 is not installed. Please install Python 3.9+."
    exit 1
fi

if ! command -v adb &> /dev/null; then
    echo_error "ADB (Android Debug Bridge) is not installed. Please install Android Platform Tools."
    exit 1
fi

echo_success "Prerequisites met."

# 3. Setup and Clone Repositories
DEFAULT_INSTALL_DIR=".."
echo -e "${BLUE}[?] Where should other components be installed? (Default: $DEFAULT_INSTALL_DIR): ${NC}\c"
read -r INSTALL_DIR_INPUT
INSTALL_DIR="${INSTALL_DIR_INPUT:-$DEFAULT_INSTALL_DIR}"

# Resolve absolute path for clarity (optional but good)
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
INSTALL_DIR_ABS=$(pwd)
cd - > /dev/null

echo_info "Using installation directory: $INSTALL_DIR_ABS"

# Function to clone if missing
ensure_repo() {
    local NAME=$1
    local URL=$2
    if [ ! -d "$INSTALL_DIR_ABS/$NAME" ]; then
        echo_info "Cloning $NAME..."
        git clone "$URL" "$INSTALL_DIR_ABS/$NAME"
    else
        echo_info "$NAME already exists."
    fi
}

ensure_repo "talos-agent" "https://github.com/Talos-Tester-AI/talos-agent.git"
ensure_repo "talos-cli" "https://github.com/Talos-Tester-AI/talos-ai.git"

# 4. Setup and Run Talos Agent
AG_DIR="$INSTALL_DIR_ABS/talos-agent"
if [ ! -d "$AG_DIR" ]; then
    echo_error "Directory $AG_DIR not found even after clone attempt!"
    exit 1
fi


echo_info "Setting up Talos Agent..."
cd "$AG_DIR"

# Create venv if needed
if [ ! -d "venv" ]; then
    echo_info "Creating Python virtual environment..."
    python3 -m venv venv
else
    echo_info "Using existing virtual environment."
fi

# Activate venv
source venv/bin/activate

# Install dependencies
echo_info "Installing agent dependencies..."
pip install -r requirements.txt > /dev/null

# Start Agent in background
echo_info "Starting Talos Agent in background..."
python main.py > agent.log 2>&1 &
AGENT_PID=$!
echo_success "Talos Agent started (PID: $AGENT_PID). Logs: $AG_DIR/agent.log"

cd ..

# 5. Setup and Run Talos CLI
CLI_DIR="$INSTALL_DIR_ABS/talos-cli"
if [ ! -d "$CLI_DIR" ]; then
    echo_error "Directory $CLI_DIR not found!"
    kill "$AGENT_PID"
    exit 1
fi

echo_info "Setting up Talos CLI..."
cd "$CLI_DIR"

# Install dependencies (only if node_modules is missing for speed, or always? usually 'npm install' is fast if up to date)
if [ ! -d "node_modules" ]; then
     echo_info "Installing CLI dependencies (this may take a while)..."
    npm install
else
    echo_info "Checking CLI dependencies..."
    npm install # Always run to ensure sync
fi

# Cleanup function to kill agent when script exits
cleanup() {
    echo_info "Stopping Talos Agent (PID: $AGENT_PID)..."
    kill "$AGENT_PID"
    echo_success "Talos Agent stopped."
}

trap cleanup EXIT INT TERM

# Start CLI
echo_info "Starting Talos CLI..."
echo_info "Press Ctrl+C to stop both Agent and CLI."

# On Mac, we just run npm run dev. On Linux, we handled the stdbuf logic in dev-clean.sh, 
# so we can rely on npm run dev calling that script or just run it directly.
# The user's dev-clean.sh already handles stdbuf check.
npm run dev
