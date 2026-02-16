#!/bin/bash

###############################################################################
# Manual Scrub Trigger
# 
# Purpose: Manually trigger a scrub with optional immediate mode
# Usage: sudo ./scripts/trigger-scrub.sh [pool_name] [--now]
###############################################################################

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Load config
for config_path in \
    "/usr/local/etc/zfs-das.conf" \
    "/etc/zfs-das.conf" \
    "$(dirname "$0")/../configs/zfs-das.conf" \
    "$HOME/.config/zfs-das.conf"; do
    if [ -f "$config_path" ]; then
        # shellcheck source=/dev/null
        source "$config_path"
        break
    fi
done

POOL_NAME="${1:-${POOL_NAME:-media_pool}}"
ZFS_BIN_PATH="${ZFS_BIN_PATH:-/usr/local/zfs/bin}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${BLUE}╔═══════════════════════════════════════╗"
echo "║   ZFS Scrub Trigger                   ║"
echo -e "╚═══════════════════════════════════════╝${NC}"
echo ""

# Check if pool exists
if ! "$ZFS_BIN_PATH/zpool" list "$POOL_NAME" &>/dev/null; then
    echo -e "${RED}✗ Pool '$POOL_NAME' not found${NC}"
    echo ""
    echo "Available pools:"
    "$ZFS_BIN_PATH/zpool" list
    exit 1
fi

# Check current scrub status
echo "Checking current scrub status..."
SCRUB_STATUS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "scan:")

echo "$SCRUB_STATUS"
echo ""

# Check if scrub is already in progress
if echo "$SCRUB_STATUS" | grep -q "scrub in progress"; then
    echo -e "${YELLOW}⚠ Scrub is already in progress${NC}"
    
    PROGRESS=$(echo "$SCRUB_STATUS" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
    echo "Progress: ${PROGRESS:-unknown}"
    echo ""
    
    read -p "Do you want to cancel the current scrub? (yes/no): " CANCEL
    
    if [ "$CANCEL" = "yes" ]; then
        echo ""
        echo "Stopping scrub..."
        if "$ZFS_BIN_PATH/zpool" scrub -s "$POOL_NAME"; then
            echo -e "${GREEN}✓ Scrub stopped${NC}"
        else
            echo -e "${RED}✗ Failed to stop scrub${NC}"
            exit 1
        fi
    else
        echo "Keeping current scrub running"
        exit 0
    fi
fi

# Get pool health
POOL_HEALTH=$("$ZFS_BIN_PATH/zpool" list -H -o health "$POOL_NAME")
echo "Pool health: $POOL_HEALTH"

if [ "$POOL_HEALTH" != "ONLINE" ]; then
    echo -e "${YELLOW}⚠ WARNING: Pool health is $POOL_HEALTH${NC}"
    echo "Scrubbing a degraded pool can help identify issues."
    echo ""
fi

# Get pool size
POOL_SIZE=$("$ZFS_BIN_PATH/zpool" list -H -o size "$POOL_NAME")
echo "Pool size: $POOL_SIZE"
echo ""

# Estimate scrub time
echo -e "${BLUE}Estimated scrub time:${NC}"
echo "  Small pool (< 1TB):   1-2 hours"
echo "  Medium pool (1-5TB):  3-8 hours"
echo "  Large pool (5-10TB):  8-24 hours"
echo "  Huge pool (> 10TB):   24+ hours"
echo ""

# Check if --now flag is present
NOW_MODE=false
if [ "$2" = "--now" ]; then
    NOW_MODE=true
fi

if [ "$NOW_MODE" = false ]; then
    read -p "Start scrub now? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo "Scrub cancelled"
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}Starting scrub...${NC}"

if "$ZFS_BIN_PATH/zpool" scrub "$POOL_NAME"; then
    echo -e "${GREEN}✓ Scrub initiated successfully${NC}"
    echo ""
    echo "You can monitor progress with:"
    echo "  watch 'zpool status $POOL_NAME | grep scan'"
    echo ""
    echo "Or check with the status utility:"
    echo "  ./scripts/check-zfs-status.sh"
    echo ""
    echo "The scrub will run in the background."
    echo "Pool remains available during scrub (with slight performance impact)."
else
    echo -e "${RED}✗ Failed to start scrub${NC}"
    exit 1
fi
