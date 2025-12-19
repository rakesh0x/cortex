#!/usr/bin/env bash
set -euo pipefail

# Cortex Linux installer (Debian / Ubuntu)
# Usage: curl -fsSL https://cortexlinux.com/install.sh | bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

error() {
  echo "ERROR: $*" >&2
  exit 1
}

echo "🧠 Cortex Linux Installer"

# Detect OS (Debian / Ubuntu only)
if [[ -r /etc/os-release ]]; then
  source /etc/os-release
  OS_ID=${ID,,}
  OS_LIKE=${ID_LIKE,,}
else
  error "Cannot detect OS"
fi

if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" && ! "$OS_LIKE" =~ debian ]]; then
  error "Unsupported OS: $OS_ID"
fi

# Check Python 3.10+
command -v python3 >/dev/null 2>&1 || \
  error "python3 not found. Install Python 3.10+"

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
MAJOR=${PYTHON_VERSION%%.*}
MINOR=${PYTHON_VERSION##*.}

if [[ "$MAJOR" -lt 3 || ( "$MAJOR" -eq 3 && "$MINOR" -lt 10 ) ]]; then
  error "Python 3.10+ required. Found: $PYTHON_VERSION"
fi

echo "Detected: ${PRETTY_NAME%% LTS}, Python $PYTHON_VERSION"
echo "Installing to ~/.cortex..."

# Create virtual environment
CORTEX_HOME="$HOME/.cortex"
VENV_PATH="$CORTEX_HOME/venv"
mkdir -p "$CORTEX_HOME"

[[ -d "$VENV_PATH" ]] || python3 -m venv "$VENV_PATH"
export PATH="$VENV_PATH/bin:$PATH"

# Install Cortex
pip install --upgrade pip >/dev/null 2>&1

if ! pip install cortex-linux >/dev/null 2>&1; then
  command -v git >/dev/null 2>&1 || error "git not available for fallback install"
  TMP_DIR=$(mktemp -d)
  git clone --depth 1 https://github.com/cortexlinux/cortex.git "$TMP_DIR"
  pip install --quiet "$TMP_DIR"
  rm -rf "$TMP_DIR"
fi

# Make cortex command available globally
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

[[ -x "$VENV_PATH/bin/cortex" ]] && \
  ln -sf "$VENV_PATH/bin/cortex" "$BIN_DIR/cortex"

# Persist PATH update
for rc in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  [[ -f "$rc" ]] || continue
  grep -q ".local/bin" "$rc" && continue
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done

# Store API key if present in environment
ENV_FILE="$CORTEX_HOME/.env"
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
fi

# Verify installation by running cortex --help
command -v cortex >/dev/null 2>&1 || \
  error "cortex command not found. Restart terminal."

cortex --help > /dev/null 2>&1 || \
  error "cortex --help failed. Please check installation."

echo "✅ Installed! Run: cortex install nginx"
