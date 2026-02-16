#!/bin/bash

###############################################################################
# Quick Snapshot Helper
# 
# Purpose: Create, list, and restore ZFS snapshots easily
# Usage: ./scripts/quick-snapshot.sh <command> [options]
###############################################################################

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

POOL_NAME="${POOL_NAME:-media_pool}"
ZFS_BIN_PATH="${ZFS_BIN_PATH:-/usr/local/zfs/bin}"

# Help function
show_help() {
    echo "Quick Snapshot Helper"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  create <dataset>            Create snapshot with timestamp"
    echo "  list [dataset]              List all snapshots"
    echo "  rollback <snapshot>         Rollback to snapshot"
    echo "  delete <snapshot>           Delete snapshot"
    echo "  diff <snapshot>             Show changes since snapshot"
    echo ""
    echo "Examples:"
    echo "  $0 create $POOL_NAME/data"
    echo "  $0 list $POOL_NAME/data"
    echo "  $0 rollback $POOL_NAME/data@backup-20241213"
    echo "  $0 delete $POOL_NAME/data@old-snapshot"
    echo "  $0 diff $POOL_NAME/data@yesterday"
    echo ""
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
    create)
        DATASET="$1"
        if [ -z "$DATASET" ]; then
            echo "Error: Dataset name required"
            echo "Usage: $0 create <dataset>"
            exit 1
        fi
        
        TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
        SNAPSHOT_NAME="${DATASET}@snapshot-${TIMESTAMP}"
        
        echo -e "${BLUE}Creating snapshot...${NC}"
        echo "Dataset: $DATASET"
        echo "Snapshot: $SNAPSHOT_NAME"
        echo ""
        
        if "$ZFS_BIN_PATH/zfs" snapshot "$SNAPSHOT_NAME"; then
            echo -e "${GREEN}✓ Snapshot created successfully${NC}"
            echo ""
            echo "To rollback:"
            echo "  $0 rollback $SNAPSHOT_NAME"
        else
            echo "✗ Failed to create snapshot"
            exit 1
        fi
        ;;
        
    list)
        DATASET="${1:-$POOL_NAME}"
        
        echo -e "${BLUE}Snapshots for: $DATASET${NC}"
        echo ""
        
        "$ZFS_BIN_PATH/zfs" list -t snapshot -r "$DATASET" -o name,used,creation
        ;;
        
    rollback)
        SNAPSHOT="$1"
        if [ -z "$SNAPSHOT" ]; then
            echo "Error: Snapshot name required"
            echo "Usage: $0 rollback <snapshot>"
            exit 1
        fi
        
        echo -e "${YELLOW}⚠ WARNING: Rollback will destroy newer snapshots and changes${NC}"
        echo "Snapshot: $SNAPSHOT"
        echo ""
        read -p "Are you sure? (yes/no): " CONFIRM
        
        if [ "$CONFIRM" = "yes" ]; then
            echo ""
            echo -e "${BLUE}Rolling back...${NC}"
            
            if "$ZFS_BIN_PATH/zfs" rollback -r "$SNAPSHOT"; then
                echo -e "${GREEN}✓ Rollback successful${NC}"
            else
                echo "✗ Rollback failed"
                exit 1
            fi
        else
            echo "Rollback cancelled"
            exit 0
        fi
        ;;
        
    delete)
        SNAPSHOT="$1"
        if [ -z "$SNAPSHOT" ]; then
            echo "Error: Snapshot name required"
            echo "Usage: $0 delete <snapshot>"
            exit 1
        fi
        
        echo -e "${YELLOW}Deleting snapshot: $SNAPSHOT${NC}"
        read -p "Are you sure? (yes/no): " CONFIRM
        
        if [ "$CONFIRM" = "yes" ]; then
            if "$ZFS_BIN_PATH/zfs" destroy "$SNAPSHOT"; then
                echo -e "${GREEN}✓ Snapshot deleted${NC}"
            else
                echo "✗ Failed to delete snapshot"
                exit 1
            fi
        else
            echo "Deletion cancelled"
            exit 0
        fi
        ;;
        
    diff)
        SNAPSHOT="$1"
        if [ -z "$SNAPSHOT" ]; then
            echo "Error: Snapshot name required"
            echo "Usage: $0 diff <snapshot>"
            exit 1
        fi
        
        echo -e "${BLUE}Changes since snapshot: $SNAPSHOT${NC}"
        echo ""
        
        "$ZFS_BIN_PATH/zfs" diff "$SNAPSHOT"
        ;;
        
    help|--help|-h)
        show_help
        exit 0
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo ""
        show_help
        exit 1
        ;;
esac
