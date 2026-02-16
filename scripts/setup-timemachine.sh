#!/bin/bash

###############################################################################
# Time Machine Setup Helper
# 
# Purpose: Creates encrypted sparse bundles for Time Machine backups on ZFS
#
# Author: macOS ZFS DAS Project
# License: MIT
#
# Author: macOS ZFS DAS Project
# License: MIT
###############################################################################

echo "=========================================="
echo "Time Machine Setup for ZFS Pool"
echo "=========================================="
echo ""

# Get pool name
read -p "Enter your ZFS pool name (default: media_pool): " POOL_NAME
POOL_NAME=${POOL_NAME:-media_pool}

# ZFS binary paths
ZPOOL="/usr/local/zfs/bin/zpool"
ZFS="/usr/local/zfs/bin/zfs"

# Verify pool exists
if ! $ZPOOL list "$POOL_NAME" &>/dev/null; then
    echo "ERROR: Pool '$POOL_NAME' not found"
    echo "Available pools:"
    $ZPOOL list
    exit 1
fi

# Get computer name
echo ""
echo "Enter a unique name for this Mac (examples: MacMini, MacBookPro, iMac)"
read -p "Computer name: " COMPUTER_NAME

if [ -z "$COMPUTER_NAME" ]; then
    echo "ERROR: Computer name cannot be empty"
    exit 1
fi

# Get backup size with validation
echo ""
echo "Enter desired backup size (examples: 500g, 1t, 2t)"
echo "Recommendation: 2-3x your used disk space"

# Check available space in pool
POOL_AVAIL=$(zfs get -H -o value available "$POOL_NAME" 2>/dev/null || echo "unknown")
if [ "$POOL_AVAIL" != "unknown" ]; then
    echo "Available space in pool: $POOL_AVAIL"
fi

# Validate backup size input
BACKUP_SIZE=""
while [ -z "$BACKUP_SIZE" ]; do
    read -p "Backup size: " SIZE_INPUT
    
    if [ -z "$SIZE_INPUT" ]; then
        echo "ERROR: Backup size cannot be empty"
        continue
    fi
    
    # Validate format (number followed by g, G, t, or T)
    if echo "$SIZE_INPUT" | grep -qE '^[0-9]+[gGtT]$'; then
        BACKUP_SIZE="$SIZE_INPUT"
    else
        echo "ERROR: Invalid format. Use format like: 500g, 1t, 2t"
        echo "       Number followed by 'g' (gigabytes) or 't' (terabytes)"
    fi
done

# Create sparse bundle
SPARSE_BUNDLE_PATH="/Volumes/$POOL_NAME/backups/${COMPUTER_NAME}-Backup.sparsebundle"

echo ""
echo "Creating sparse bundle..."
echo "Path: $SPARSE_BUNDLE_PATH"
echo "Size: $BACKUP_SIZE"
echo ""

hdiutil create -size "$BACKUP_SIZE" -type SPARSEBUNDLE -fs "HFS+J" \
  -volname "${COMPUTER_NAME}-TM" \
  -uid $(id -u) -gid $(id -g) \
  "$SPARSE_BUNDLE_PATH"

if [ $? -eq 0 ]; then
    echo "✓ Sparse bundle created successfully"
else
    echo "✗ Failed to create sparse bundle"
    exit 1
fi

# Mount it
echo ""
echo "Mounting sparse bundle..."
hdiutil attach "$SPARSE_BUNDLE_PATH"

# Set as Time Machine destination
echo ""
read -p "Set as Time Machine destination now? (y/n): " SET_TM

if [ "$SET_TM" = "y" ] || [ "$SET_TM" = "Y" ]; then
    sudo diskutil enableOwnership "/Volumes/${COMPUTER_NAME}-TM"
    sudo tmutil setdestination "/Volumes/${COMPUTER_NAME}-TM"
    
    echo ""
    echo "✓ Time Machine configured!"
    echo ""
    echo "Next steps:"
    echo "1. Open System Settings > General > Time Machine"
    echo "2. Verify ${COMPUTER_NAME}-TM is selected"
    echo "3. Enable 'Back Up Automatically'"
fi

echo ""
echo "Setup complete!"
