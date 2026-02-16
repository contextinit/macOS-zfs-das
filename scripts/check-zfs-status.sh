#!/bin/bash

###############################################################################
# ZFS Status Check Utility
# 
# Purpose: Check ZFS pool health and mount status
# Usage: ./scripts/check-zfs-status.sh [pool_name]
###############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load config if available
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

# Use provided pool name or default from config
POOL_NAME="${1:-${POOL_NAME:-media_pool}}"
ZFS_BIN_PATH="${ZFS_BIN_PATH:-/usr/local/zfs/bin}"

echo -e "${BLUE}╔═══════════════════════════════════════╗"
echo "║   ZFS Status Check                    ║"
echo -e "╚═══════════════════════════════════════╝${NC}"
echo ""

# Check if ZFS is installed
if [ ! -x "$ZFS_BIN_PATH/zpool" ]; then
    echo -e "${RED}✗ ZFS not found at $ZFS_BIN_PATH${NC}"
    echo ""
    echo "Install OpenZFS from: https://openzfsonosx.github.io/"
    exit 1
fi

echo -e "${GREEN}✓ ZFS installed${NC}"
echo ""

# Check if pool exists
echo -e "${BLUE}Checking pool: $POOL_NAME${NC}"
echo "-------------------------------------------"

if ! "$ZFS_BIN_PATH/zpool" list "$POOL_NAME" &>/dev/null; then
    echo -e "${RED}✗ Pool '$POOL_NAME' not found${NC}"
    echo ""
    echo "Available pools:"
    "$ZFS_BIN_PATH/zpool" list 2>/dev/null || echo "No pools found"
    exit 1
fi

# Get pool health
POOL_HEALTH=$("$ZFS_BIN_PATH/zpool" list -H -o health "$POOL_NAME")
if [ "$POOL_HEALTH" = "ONLINE" ]; then
    echo -e "Health: ${GREEN}✓ $POOL_HEALTH${NC}"
elif [ "$POOL_HEALTH" = "DEGRADED" ]; then
    echo -e "Health: ${YELLOW}⚠ $POOL_HEALTH${NC}"
else
    echo -e "Health: ${RED}✗ $POOL_HEALTH${NC}"
fi

# Get pool capacity
POOL_CAP=$("$ZFS_BIN_PATH/zpool" list -H -o capacity "$POOL_NAME")
CAP_NUM=${POOL_CAP%\%}

if [ "$CAP_NUM" -lt 70 ]; then
    echo -e "Capacity: ${GREEN}$POOL_CAP${NC}"
elif [ "$CAP_NUM" -lt 85 ]; then
    echo -e "Capacity: ${YELLOW}⚠ $POOL_CAP${NC}"
else
    echo -e "Capacity: ${RED}⚠ $POOL_CAP (Low space!)${NC}"
fi

# Get pool size
POOL_SIZE=$("$ZFS_BIN_PATH/zpool" list -H -o size "$POOL_NAME")
echo "Size: $POOL_SIZE"

# Get pool usage
POOL_USED=$("$ZFS_BIN_PATH/zpool" list -H -o allocated "$POOL_NAME")
POOL_FREE=$("$ZFS_BIN_PATH/zpool" list -H -o free "$POOL_NAME")
echo "Used: $POOL_USED | Free: $POOL_FREE"

echo ""

# Check for errors
echo -e "${BLUE}Error Check${NC}"
echo "-------------------------------------------"
ERRORS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "errors:" | grep -v "No known data errors")

if [ -z "$ERRORS" ]; then
    echo -e "${GREEN}✓ No errors detected${NC}"
else
    echo -e "${RED}✗ Errors found:${NC}"
    echo "$ERRORS"
fi

echo ""

# Check scrub status
echo -e "${BLUE}Scrub Status${NC}"
echo "-------------------------------------------"
SCRUB_STATUS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "scan:")

if echo "$SCRUB_STATUS" | grep -q "scrub in progress"; then
    PROGRESS=$(echo "$SCRUB_STATUS" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
    echo -e "${YELLOW}⟳ Scrub in progress: ${PROGRESS}${NC}"
elif echo "$SCRUB_STATUS" | grep -q "scrub repaired"; then
    echo -e "${GREEN}✓ Last scrub: $(echo "$SCRUB_STATUS" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}')${NC}"
else
    echo "$SCRUB_STATUS"
fi

echo ""

# Check datasets and encryption
echo -e "${BLUE}Datasets${NC}"
echo "-------------------------------------------"

# Get all datasets for this pool
DATASETS=$("$ZFS_BIN_PATH/zfs" list -H -o name -r "$POOL_NAME" 2>/dev/null)

if [ -z "$DATASETS" ]; then
    echo "No datasets found"
else
    echo -e "${BLUE}Name                          Mounted  Encrypted  Size${NC}"
    
    while IFS= read -r dataset; do
        # Get mount status
        MOUNTED=$("$ZFS_BIN_PATH/zfs" get -H -o value mounted "$dataset")
        if [ "$MOUNTED" = "yes" ]; then
            MOUNT_ICON="${GREEN}✓${NC}"
        else
            MOUNT_ICON="${RED}✗${NC}"
        fi
        
        # Get encryption status
        ENCRYPTION=$("$ZFS_BIN_PATH/zfs" get -H -o value encryption "$dataset")
        if [ "$ENCRYPTION" = "off" ]; then
            ENC_ICON="-"
        elif [ "$ENCRYPTION" = "aes-256-gcm" ]; then
            KEY_STATUS=$("$ZFS_BIN_PATH/zfs" get -H -o value keystatus "$dataset")
            if [ "$KEY_STATUS" = "available" ]; then
                ENC_ICON="${GREEN}🔒${NC}"
            else
                ENC_ICON="${RED}🔒${NC}"
            fi
        else
            ENC_ICON="🔒"
        fi
        
        # Get size
        SIZE=$("$ZFS_BIN_PATH/zfs" get -H -o value used "$dataset")
        
        # Format and print
        printf "%-30s %b %-7s %b %-4s  %s\n" \
            "$(basename "$dataset")" \
            "$MOUNT_ICON" \
            "$MOUNTED" \
            "$ENC_ICON" \
            "$ENCRYPTION" \
            "$SIZE"
    done <<< "$DATASETS"
fi

echo ""

# Check auto-mount service
echo -e "${BLUE}Auto-Mount Service${NC}"
echo "-------------------------------------------"

if [ -f "/Library/LaunchDaemons/com.local.zfs.automount.plist" ]; then
    if launchctl list | grep -q "com.local.zfs.automount"; then
        echo -e "${GREEN}✓ Service loaded${NC}"
        
        # Check last run
        if [ -f "/var/log/zfs-automount.log" ]; then
            LAST_RUN=$(tail -1 /var/log/zfs-automount.log | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' || echo "Unknown")
            echo "Last run: $LAST_RUN"
        fi
    else
        echo -e "${YELLOW}⚠ Service not loaded${NC}"
        echo "Load with: sudo launchctl load /Library/LaunchDaemons/com.local.zfs.automount.plist"
    fi
else
    echo -e "${YELLOW}⚠ Service not installed${NC}"
    echo "See docs/SETUP.md for installation instructions"
fi

echo ""

# Overall status
echo -e "${BLUE}╔═══════════════════════════════════════╗"
echo "║   Overall Status                      ║"
echo -e "╚═══════════════════════════════════════╝${NC}"

if [ "$POOL_HEALTH" = "ONLINE" ] && [ -z "$ERRORS" ] && [ "$CAP_NUM" -lt 85 ]; then
    echo -e "${GREEN}✓ All systems healthy${NC}"
    echo ""
    echo "Your ZFS pool is operating normally."
    exit 0
elif [ "$POOL_HEALTH" = "DEGRADED" ] || [ -n "$ERRORS" ]; then
    echo -e "${RED}✗ Issues detected${NC}"
    echo ""
    echo "Run 'sudo zpool status -v $POOL_NAME' for details"
    exit 1
else
    echo -e "${YELLOW}⚠ Warnings present${NC}"
    echo ""
    echo "Review the status above and take action if needed."
    exit 0
fi
