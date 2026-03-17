#!/bin/bash
# install-swiftbar.sh — Download and install SwiftBar from GitHub Releases
#
# SwiftBar is MIT-licensed software by Ameba Labs.
# Source: https://github.com/swiftbar/SwiftBar
# See THIRD-PARTY-LICENSES.md for the full license text.
#
# Usage:
#   sudo ./scripts/install-swiftbar.sh [--plugin-dir <path>]
#
# Options:
#   --plugin-dir <path>   Directory to install ZFS plugins into
#                         (default: ~/Library/Application Support/SwiftBar/Plugins)

set -euo pipefail

# ────────────────────────────────────────────────────────────
# Config
# ────────────────────────────────────────────────────────────
SWIFTBAR_APP="/Applications/SwiftBar.app"
GITHUB_API="https://api.github.com/repos/swiftbar/SwiftBar/releases/latest"
DEFAULT_PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
PLUGIN_DIR="${DEFAULT_PLUGIN_DIR}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SWIFTBAR_PLUGIN_SRC="$REPO_ROOT/swiftbar"
TMP_DIR="$(mktemp -d)"

# ────────────────────────────────────────────────────────────
# Parse arguments
# ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --plugin-dir)
            PLUGIN_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# ────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────
log()  { echo "[install-swiftbar] $*"; }
warn() { echo "[install-swiftbar] WARNING: $*" >&2; }
die()  { echo "[install-swiftbar] ERROR: $*" >&2; exit 1; }

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_cmd() {
    command -v "$1" &>/dev/null || die "Required command not found: $1"
}

# ────────────────────────────────────────────────────────────
# Checks
# ────────────────────────────────────────────────────────────
require_cmd curl
require_cmd unzip

# Must run on macOS
[[ "$(uname)" == "Darwin" ]] || die "This script requires macOS."

# ────────────────────────────────────────────────────────────
# 1. Fetch latest SwiftBar release info
# ────────────────────────────────────────────────────────────
log "Fetching latest SwiftBar release from GitHub..."

RELEASE_JSON=$(curl -fsSL "$GITHUB_API") \
    || die "Failed to reach GitHub API. Check your internet connection."

# Extract download URL for the .zip asset
DOWNLOAD_URL=$(echo "$RELEASE_JSON" \
    | grep '"browser_download_url"' \
    | grep -i '\.zip' \
    | head -1 \
    | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')

VERSION=$(echo "$RELEASE_JSON" \
    | grep '"tag_name"' \
    | head -1 \
    | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')

[[ -n "$DOWNLOAD_URL" ]] || die "Could not find a .zip download URL in the latest release."
[[ -n "$VERSION"      ]] || VERSION="unknown"

log "Latest version: $VERSION"
log "Download URL:   $DOWNLOAD_URL"

# ────────────────────────────────────────────────────────────
# 2. Check if SwiftBar is already installed at this version
# ────────────────────────────────────────────────────────────
if [[ -d "$SWIFTBAR_APP" ]]; then
    INSTALLED_VERSION=$(defaults read "$SWIFTBAR_APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "")
    if [[ -n "$INSTALLED_VERSION" ]] && [[ "v${INSTALLED_VERSION}" == "$VERSION" || "$INSTALLED_VERSION" == "$VERSION" ]]; then
        log "SwiftBar $INSTALLED_VERSION is already installed. Skipping download."
    else
        log "Updating SwiftBar from ${INSTALLED_VERSION:-unknown} → $VERSION..."
        DOWNLOAD_NEEDED=true
    fi
else
    log "SwiftBar not found. Installing $VERSION..."
    DOWNLOAD_NEEDED=true
fi

# ────────────────────────────────────────────────────────────
# 3. Download and install SwiftBar
# ────────────────────────────────────────────────────────────
if [[ "${DOWNLOAD_NEEDED:-false}" == "true" ]]; then
    ZIP_PATH="$TMP_DIR/SwiftBar.zip"

    log "Downloading SwiftBar..."
    curl -fsSL --progress-bar -o "$ZIP_PATH" "$DOWNLOAD_URL" \
        || die "Download failed. Check your internet connection."

    log "Extracting SwiftBar.zip..."
    unzip -q "$ZIP_PATH" -d "$TMP_DIR/" \
        || die "Failed to extract SwiftBar.zip"

    APP_BUNDLE=$(find "$TMP_DIR" -name "SwiftBar.app" -maxdepth 3 | head -1)
    [[ -n "$APP_BUNDLE" ]] || die "SwiftBar.app not found in the downloaded archive."

    # Remove existing installation
    if [[ -d "$SWIFTBAR_APP" ]]; then
        log "Removing existing installation..."
        rm -rf "$SWIFTBAR_APP"
    fi

    log "Installing SwiftBar to /Applications/..."
    cp -R "$APP_BUNDLE" "/Applications/"

    # Remove quarantine attribute so macOS Gatekeeper doesn't block it
    log "Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$SWIFTBAR_APP" 2>/dev/null || true

    log "SwiftBar $VERSION installed successfully."
fi

# ────────────────────────────────────────────────────────────
# 4. Install ZFS plugins
# ────────────────────────────────────────────────────────────
log "Installing ZFS monitoring plugins to: $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"

for plugin_src in "$SWIFTBAR_PLUGIN_SRC"/*.sh; do
    plugin_name="$(basename "$plugin_src")"
    plugin_dst="$PLUGIN_DIR/$plugin_name"

    cp "$plugin_src" "$plugin_dst"
    chmod +x "$plugin_dst"
    log "  Installed: $plugin_name"
done

# ────────────────────────────────────────────────────────────
# 5. Launch SwiftBar (if not already running)
# ────────────────────────────────────────────────────────────
if ! pgrep -x SwiftBar &>/dev/null; then
    log "Launching SwiftBar..."
    open -a SwiftBar --args --pluginsURL "file://$PLUGIN_DIR" &
    sleep 2
else
    log "SwiftBar is already running. Plugins will load on next refresh."
    log "You can also restart SwiftBar from its menu bar icon."
fi

# ────────────────────────────────────────────────────────────
# Done
# ────────────────────────────────────────────────────────────
log ""
log "Setup complete!"
log "  SwiftBar:    $VERSION  →  $SWIFTBAR_APP"
log "  Plugin dir:  $PLUGIN_DIR"
log ""
log "If SwiftBar asks to select a plugin folder, choose:"
log "  $PLUGIN_DIR"
