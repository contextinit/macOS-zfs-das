#!/bin/bash
set -euo pipefail

###############################################################################
# SwiftBar Monitoring Setup Script for macOS
# 
# Purpose: Interactive wizard to set up SwiftBar ZFS monitoring
#          Installs SwiftBar, configures plugins, and customizes for your pool
#
# Usage: ./setup-monitoring.sh (no sudo required)
#
# Author: macOS ZFS DAS Project
# License: MIT
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
ZFS_BIN_PATH="/usr/local/zfs/bin"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFTBAR_PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"

# Functions
print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if SwiftBar is installed
check_swiftbar() {
    if [ -d "/Applications/SwiftBar.app" ]; then
        print_success "SwiftBar is installed"
        return 0
    else
        return 1
    fi
}

# Install SwiftBar using the bundled install script
install_swiftbar() {
    print_header "Installing SwiftBar"

    echo "SwiftBar (MIT, Copyright 2020 Ameba Labs) will be downloaded"
    echo "from the official GitHub Releases and installed to /Applications/."
    echo "See THIRD-PARTY-LICENSES.md for the full license text."
    echo ""

    local installer="$PROJECT_DIR/scripts/install-swiftbar.sh"
    if [[ ! -x "$installer" ]]; then
        print_error "install-swiftbar.sh not found or not executable: $installer"
        return 1
    fi

    if bash "$installer" --plugin-dir "$SWIFTBAR_PLUGIN_DIR"; then
        print_success "SwiftBar installed successfully"
        return 0
    else
        print_error "SwiftBar installation failed"
        return 1
    fi
}

# Create SwiftBar plugin directory
setup_plugin_directory() {
    if [ ! -d "$SWIFTBAR_PLUGIN_DIR" ]; then
        print_info "Creating SwiftBar plugin directory..."
        mkdir -p "$SWIFTBAR_PLUGIN_DIR"
        print_success "Plugin directory created"
    else
        print_success "Plugin directory exists"
    fi
}

# Validate that a value contains only safe characters for use in sed replacements
# and ZFS pool/volume names (alphanumeric, hyphens, underscores).
validate_name() {
    local label="$1"
    local value="$2"
    if [[ ! "$value" =~ ^[a-zA-Z][a-zA-Z0-9_-]{0,63}$ ]]; then
        print_error "$label contains invalid characters. Use letters, numbers, hyphens, or underscores only."
        return 1
    fi
}

# Customize plugin for user's pool
customize_plugin() {
    local plugin_file="$1"
    local pool_name="$2"
    local tm_volume="$3"

    # Use | as the sed delimiter to avoid conflicts with / in paths
    sed -i '' "s|POOL_NAME=\"media_pool\"|POOL_NAME=\"${pool_name}\"|g" "$plugin_file"

    # Replace Time Machine volume if provided
    if [ -n "$tm_volume" ]; then
        sed -i '' "s|RMMacMM4|${tm_volume}|g" "$plugin_file"
    fi

    print_success "Plugin customized for pool: $pool_name"
}

# Install plugin
install_plugin() {
    local plugin_name="$1"
    local source_path="$PROJECT_DIR/swiftbar/$plugin_name"
    local dest_path="$SWIFTBAR_PLUGIN_DIR/$plugin_name"
    
    if [ ! -f "$source_path" ]; then
        print_error "Plugin not found: $source_path"
        return 1
    fi
    
    print_info "Installing $plugin_name..."
    cp "$source_path" "$dest_path"
    chmod +x "$dest_path"
    
    print_success "Plugin installed: $plugin_name"
}

# Main script
clear
print_header "ZFS Monitoring Setup Wizard"

echo "This wizard will set up SwiftBar monitoring for your ZFS pool."
echo "You'll get a menu bar widget showing:"
echo "  • Pool health and status"
echo "  • Capacity and usage"
echo "  • Drive status"
echo "  • Scrub progress"
echo "  • Time Machine backups"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
clear

# Step 1: Check/Install SwiftBar
print_header "Step 1: SwiftBar Installation"

if ! check_swiftbar; then
    print_info "SwiftBar is not installed"
    echo ""
    read -p "Install SwiftBar now? (y/n): " INSTALL_SB
    
    if [ "$INSTALL_SB" = "y" ] || [ "$INSTALL_SB" = "Y" ]; then
        install_swiftbar
        if [ $? -ne 0 ]; then
            exit 1
        fi
    else
        print_error "SwiftBar is required for monitoring"
        exit 1
    fi
fi

# Step 2: Set up plugin directory
print_header "Step 2: Plugin Directory Setup"
setup_plugin_directory

# Step 3: Get pool name
print_header "Step 3: Pool Configuration"

echo "Available ZFS pools:"
echo ""
"$ZFS_BIN_PATH/zpool" list -H -o name 2>/dev/null || {
    print_warning "No pools found or ZFS not running"
    echo ""
}

read -p "Enter your pool name (default: media_pool): " POOL_NAME
POOL_NAME=${POOL_NAME:-media_pool}
validate_name "Pool name" "$POOL_NAME"

print_success "Pool name: $POOL_NAME"
echo ""

# Step 4: Time Machine configuration (optional)
print_header "Step 4: Time Machine Configuration (Optional)"

echo "Do you use Time Machine backups on this ZFS pool?"
read -p "Configure Time Machine monitoring? (y/n): " USE_TM

TM_VOLUME=""
if [ "$USE_TM" = "y" ] || [ "$USE_TM" = "Y" ]; then
    echo ""
    echo "What is your Time Machine backup volume name?"
    echo "(This is the name shown in Finder when the sparse bundle is mounted)"
    read -p "Volume name: " TM_VOLUME
    validate_name "Time Machine volume name" "$TM_VOLUME"
fi

# Step 5: Choose monitoring plugin
print_header "Step 5: Select Monitoring Plugin"

echo "Choose a monitoring plugin:"
echo ""
echo "  1. Basic Monitor (zfs-monitor.30s.sh)"
echo "     • Simple, clean interface"
echo "     • Shows essential metrics"
echo "     • Lower resource usage"
echo ""
echo "  2. Advanced Monitor (zfs-advanced.30s.sh)"
echo "     • Detailed metrics"
echo "     • Capacity trending"
echo "     • ARC statistics"
echo "     • Historical graphs"
echo ""

read -p "Select plugin (1 or 2): " PLUGIN_CHOICE

case "$PLUGIN_CHOICE" in
    1)
        PLUGIN_NAME="zfs-monitor.30s.sh"
        ;;
    2)
        PLUGIN_NAME="zfs-advanced.30s.sh"
        ;;
    *)
        print_error "Invalid choice, using basic monitor"
        PLUGIN_NAME="zfs-monitor.30s.sh"
        ;;
esac

print_success "Selected: $PLUGIN_NAME"
echo ""

# Step 6: Install and configure
print_header "Step 6: Installing Plugin"

# Install plugin
install_plugin "$PLUGIN_NAME"

# Customize for user's settings
PLUGIN_PATH="$SWIFTBAR_PLUGIN_DIR/$PLUGIN_NAME"
customize_plugin "$PLUGIN_PATH" "$POOL_NAME" "$TM_VOLUME"

# Make executable
chmod +x "$PLUGIN_PATH"

echo ""
print_header "Setup Complete!"

echo ""
print_success "SwiftBar monitoring has been configured!"
echo ""

print_info "Installation details:"
echo "  Plugin: $PLUGIN_NAME"
echo "  Location: $SWIFTBAR_PLUGIN_DIR"
echo "  Pool: $POOL_NAME"
[ -n "$TM_VOLUME" ] && echo "  Time Machine: $TM_VOLUME"
echo ""

print_info "Next steps:"
echo "  1. Launch SwiftBar (or restart if already running)"
echo "  2. Look for the ZFS monitor in your menu bar"
echo "  3. Click it to see detailed pool information"
echo ""

# Offer to launch SwiftBar
read -p "Launch SwiftBar now? (y/n): " LAUNCH_SB

if [ "$LAUNCH_SB" = "y" ] || [ "$LAUNCH_SB" = "Y" ]; then
    print_info "Launching SwiftBar..."
    open -a SwiftBar
    sleep 2
    print_success "SwiftBar launched!"
    echo ""
    echo "Check your menu bar for the ZFS monitor icon 📊"
fi

echo ""
print_info "Plugin refresh interval: 30 seconds"
echo ""

print_success "Monitoring setup complete!"
