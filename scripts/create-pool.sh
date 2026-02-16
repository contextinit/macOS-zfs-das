#!/bin/bash

###############################################################################
# ZFS Pool Creation Script for macOS
# 
# Purpose: Interactive wizard to create ZFS pools with RAID configurations
#          Guides users through drive selection, RAID type, and pool options
#
# Usage: sudo ./create-pool.sh
#
# Author: macOS ZFS DAS Project
# License: MIT
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ZFS binary paths
ZFS_BIN_PATH="/usr/local/zfs/bin"
ZPOOL="$ZFS_BIN_PATH/zpool"
ZFS="$ZFS_BIN_PATH/zfs"

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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if OpenZFS is installed
check_zfs_installed() {
    if [ ! -f "$ZPOOL" ]; then
        print_error "OpenZFS not found at $ZFS_BIN_PATH"
        echo ""
        echo "Please install OpenZFS first:"
        echo "  Download from: https://openzfsonosx.github.io/"
        echo "  Install the .pkg file for your macOS version"
        exit 1
    fi
    
    print_success "OpenZFS found: $($ZPOOL version | head -1)"
}

# Detect available drives
detect_drives() {
    print_info "Detecting available drives..."
    echo ""
    
    # Get list of disks
    diskutil list | grep -E "^/dev/disk[0-9]+"
    echo ""
    
    # Show detailed info
    print_info "Drive details:"
    diskutil list | grep -E "disk[0-9]+ " | while read -r line; do
        disk=$(echo "$line" | awk '{print $1}')
        size=$(diskutil info "$disk" | grep "Disk Size" | awk -F: '{print $2}' | xargs)
        echo "  $disk - $size"
    done
    echo ""
}

# Validate disk selection
validate_disks() {
    local disks="$1"
    local count=0
    
    for disk in $disks; do
        if ! diskutil info "$disk" &>/dev/null; then
            print_error "Invalid disk: $disk"
            return 1
        fi
        count=$((count + 1))
    done
    
    echo "$count"
}

# Main script
clear
print_header "ZFS Pool Creation Wizard"

check_root
check_zfs_installed

echo "This wizard will guide you through creating a ZFS pool."
echo "It will ask you to select drives and configure RAID options."
echo ""
print_warning "WARNING: All data on selected drives will be DESTROYED!"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
clear

# Step 1: Pool Name
print_header "Step 1: Pool Name"
echo "Choose a name for your ZFS pool (e.g., media_pool, data_pool, backup_pool)"
echo ""
read -p "Pool name: " POOL_NAME

if [ -z "$POOL_NAME" ]; then
    print_error "Pool name cannot be empty"
    exit 1
fi

# Check if pool already exists
if $ZPOOL list "$POOL_NAME" &>/dev/null; then
    print_error "Pool '$POOL_NAME' already exists!"
    echo ""
    echo "Existing pools:"
    $ZPOOL list
    exit 1
fi

print_success "Pool name: $POOL_NAME"
echo ""

# Step 2: Drive Selection
print_header "Step 2: Select Drives"
detect_drives

print_warning "Enter disk identifiers separated by spaces (e.g., disk2 disk3 disk4)"
echo "Do NOT include /dev/ prefix or partition numbers"
echo ""
read -p "Disks to use: " DISK_INPUT

# Convert to array
read -ra DISKS <<< "$DISK_INPUT"

# Validate disks
DISK_COUNT=$(validate_disks "${DISKS[*]}")
if [ $? -ne 0 ]; then
    exit 1
fi

if [ "$DISK_COUNT" -lt 1 ]; then
    print_error "You must select at least 1 disk"
    exit 1
fi

print_success "Selected $DISK_COUNT disk(s)"
echo ""

# Step 3: RAID Configuration
print_header "Step 3: RAID Configuration"

echo "Available RAID types:"
echo ""
echo "  1. stripe  - No redundancy, maximum capacity and speed"
echo "              Capacity: 100% | Survives: 0 drive failures"
echo "              Minimum: 1 drive"
echo ""
echo "  2. mirror  - Full redundancy, 50% capacity"
echo "              Capacity: 50% | Survives: n-1 drive failures"
echo "              Minimum: 2 drives"
echo ""
echo "  3. raidz1  - RAID-5 equivalent, single parity"
echo "              Capacity: (n-1)/n | Survives: 1 drive failure"
echo "              Minimum: 3 drives (recommended)"
echo ""
echo "  4. raidz2  - RAID-6 equivalent, double parity"
echo "              Capacity: (n-2)/n | Survives: 2 drive failures"
echo "              Minimum: 4 drives (recommended)"
echo ""
echo "  5. raidz3  - Triple parity"
echo "              Capacity: (n-3)/n | Survives: 3 drive failures"
echo "              Minimum: 5 drives (recommended)"
echo ""

read -p "Select RAID type (1-5): " RAID_CHOICE

case "$RAID_CHOICE" in
    1)
        RAID_TYPE="stripe"
        MIN_DISKS=1
        ;;
    2)
        RAID_TYPE="mirror"
        MIN_DISKS=2
        ;;
    3)
        RAID_TYPE="raidz1"
        MIN_DISKS=3
        ;;
    4)
        RAID_TYPE="raidz2"
        MIN_DISKS=4
        ;;
    5)
        RAID_TYPE="raidz3"
        MIN_DISKS=5
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Validate disk count for RAID type
if [ "$DISK_COUNT" -lt "$MIN_DISKS" ]; then
    print_error "$RAID_TYPE requires at least $MIN_DISKS disks (you selected $DISK_COUNT)"
    exit 1
fi

print_success "RAID type: $RAID_TYPE"
echo ""

# Step 4: Confirmation
print_header "Step 4: Confirmation"

echo "Pool configuration:"
echo "  Pool name: $POOL_NAME"
echo "  RAID type: $RAID_TYPE"
echo "  Disks (${DISK_COUNT}): ${DISKS[*]}"
echo ""

# Build disk paths
DISK_PATHS=""
for disk in "${DISKS[@]}"; do
    DISK_PATHS="$DISK_PATHS /dev/$disk"
done

print_warning "ALL DATA ON THESE DISKS WILL BE PERMANENTLY DELETED!"
echo ""
read -p "Type 'YES' to confirm and create pool: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    print_info "Pool creation cancelled"
    exit 0
fi

echo ""
print_header "Creating Pool..."

# Create the pool
print_info "Creating ZFS pool..."
if [ "$RAID_TYPE" = "stripe" ]; then
    # Simple stripe (no vdev keyword)
    $ZPOOL create -f -o ashift=12 -O compression=lz4 -O atime=off "$POOL_NAME" $DISK_PATHS
else
    # RAID with vdev
    $ZPOOL create -f -o ashift=12 -O compression=lz4 -O atime=off "$POOL_NAME" "$RAID_TYPE" $DISK_PATHS
fi

if [ $? -eq 0 ]; then
    print_success "Pool created successfully!"
else
    print_error "Failed to create pool"
    exit 1
fi

echo ""
print_info "Pool status:"
$ZPOOL status "$POOL_NAME"

echo ""
print_header "Creating Default Datasets..."

# Create standard datasets
print_info "Creating /data dataset..."
$ZFS create "$POOL_NAME/data"

print_info "Creating /backups dataset..."
$ZFS create "$POOL_NAME/backups"

print_success "Default datasets created"

echo ""
print_header "Pool Creation Complete!"

echo ""
echo "Your ZFS pool is ready to use:"
echo "  Pool name: $POOL_NAME"
echo "  Mount point: /Volumes/$POOL_NAME"
echo "  Data: /Volumes/$POOL_NAME/data"
echo "  Backups: /Volumes/$POOL_NAME/backups"
echo ""
print_info "Next steps:"
echo "  1. Set up encryption: sudo ./setup-encryption.sh"
echo "  2. Configure auto-mount: sudo cp scripts/zfs-automount.sh /usr/local/bin/"
echo "  3. Set up monitoring: ./setup-monitoring.sh"
echo ""

# Show final pool list
$ZPOOL list "$POOL_NAME"
echo ""

print_success "Pool creation complete!"
