#!/bin/bash
# Oscar CLI Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/TheRealOpsCanvas/releases/main/oscar/install.sh | bash

set -e

# Configuration
GITHUB_REPO="TheRealOpsCanvas/releases"
BINARY_NAME="oscar"
INSTALL_DIR="${OSCAR_INSTALL_DIR:-$HOME/.local/bin}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() { echo -e "${CYAN}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}" >&2; exit 1; }

# Detect OS and architecture
detect_platform() {
    local os arch

    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="macos" ;;
        MINGW*|MSYS*|CYGWIN*) os="windows" ;;
        *) error "Unsupported operating system: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) error "Unsupported architecture: $(uname -m)" ;;
    esac

    echo "${os}-${arch}"
}

# Get latest Oscar version from GitHub
get_latest_version() {
    # Find the latest oscar-v* tag (not just any release)
    curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases" | 
        grep '"tag_name"' | 
        grep "oscar-v" |
        head -1 |
        sed -E 's/.*"oscar-v([^"]+)".*/\1/'
}

# Download and install
install() {
    local platform version download_url binary_name

    info "
╔════════════════════════════════════════════╗
║         Oscar CLI Installer                ║
╚════════════════════════════════════════════╝
"

    # Detect platform
    platform=$(detect_platform)
    info "Detected platform: ${platform}"

    # Get version
    if [ -n "$OSCAR_VERSION" ]; then
        version="$OSCAR_VERSION"
        info "Installing version: ${version} (from OSCAR_VERSION)"
    else
        info "Fetching latest version..."
        version=$(get_latest_version)
        if [ -z "$version" ]; then
            error "Could not determine latest version"
        fi
        info "Latest version: ${version}"
    fi

    # Construct binary name
    case "$platform" in
        windows-*) binary_name="oscar-${platform}.exe" ;;
        *) binary_name="oscar-${platform}" ;;
    esac

    # Download URL
    download_url="https://github.com/${GITHUB_REPO}/releases/download/oscar-v${version}/${binary_name}"

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Download
    info "Downloading ${binary_name}..."
    if command -v curl &> /dev/null; then
        curl -fsSL "$download_url" -o "${INSTALL_DIR}/${BINARY_NAME}"
    elif command -v wget &> /dev/null; then
        wget -q "$download_url" -O "${INSTALL_DIR}/${BINARY_NAME}"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi

    # Make executable
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

    success "✓ Installed oscar to ${INSTALL_DIR}/${BINARY_NAME}"

    # Check if in PATH
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
        warn "
⚠ ${INSTALL_DIR} is not in your PATH.

Add it by running:"

        case "$SHELL" in
            */zsh)
                echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
                echo "  source ~/.zshrc"
                ;;
            */bash)
                echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
                echo "  source ~/.bashrc"
                ;;
            *)
                echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
                ;;
        esac
        echo ""
    fi

    success "
╔════════════════════════════════════════════╗
║         Installation Complete!             ║
╚════════════════════════════════════════════╝

Get started:

  1. Set your Anthropic API key:
     export ANTHROPIC_API_KEY=\"your-key\"

  2. Start Oscar and login:
     oscar
     # Then use /login inside Oscar

For help: oscar --help
"
}

# Run installer
install

