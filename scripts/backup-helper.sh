#!/bin/bash

###############################################################################
# Backup Helper
# 
# Purpose: Simple backup and restore operations
# Usage: ./scripts/backup-helper.sh <command> [options]
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

ZFS_BIN_PATH="${ZFS_BIN_PATH:-/usr/local/zfs/bin}"

# Help function
show_help() {
    echo "Backup Helper"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  send <dataset> <file>       Export dataset to file"
    echo "  receive <file> <dataset>    Import dataset from file"
    echo "  replicate <src> <dst>       Replicate dataset to another pool"
    echo "  verify <file>               Verify backup file integrity"
    echo ""
    echo "Examples:"
    echo "  $0 send media_pool/data /backup/data.zfs"
    echo "  $0 receive /backup/data.zfs media_pool/restored"
    echo "  $0 replicate media_pool/data backup_pool/data"
    echo "  $0 verify /backup/data.zfs"
    echo ""
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

COMMAND="$1"
shift || true

case "$COMMAND" in
    send)
        DATASET="$1"
        OUTPUT_FILE="$2"
        
        if [ -z "$DATASET" ] || [ -z "$OUTPUT_FILE" ]; then
            echo "Error: Dataset and output file required"
            echo "Usage: $0 send <dataset> <file>"
            exit 1
        fi
        
        echo -e "${BLUE}Exporting dataset to file...${NC}"
        echo "Dataset: $DATASET"
        echo "Output: $OUTPUT_FILE"
        echo ""
        
        # Create snapshot for consistent backup
        SNAPSHOT="${DATASET}@backup-$(date '+%Y%m%d-%H%M%S')"
        echo "Creating snapshot: $SNAPSHOT"
        
        if ! "$ZFS_BIN_PATH/zfs" snapshot "$SNAPSHOT"; then
            echo -e "${RED}✗ Failed to create snapshot${NC}"
            exit 1
        fi
        
        # Send to file
        echo "Sending data..."
        if "$ZFS_BIN_PATH/zfs" send -v "$SNAPSHOT" > "$OUTPUT_FILE"; then
            echo -e "${GREEN}✓ Export successful${NC}"
            echo ""
            SIZE=$(du -h "$OUTPUT_FILE" | awk '{print $1}')
            echo "Backup size: $SIZE"
            echo "Snapshot: $SNAPSHOT (kept for incremental backups)"
        else
            echo -e "${RED}✗ Export failed${NC}"
            # Clean up snapshot
            "$ZFS_BIN_PATH/zfs" destroy "$SNAPSHOT" 2>/dev/null || true
            exit 1
        fi
        ;;
        
    receive)
        INPUT_FILE="$1"
        DATASET="$2"
        
        if [ -z "$INPUT_FILE" ] || [ -z "$DATASET" ]; then
            echo "Error: Input file and dataset required"
            echo "Usage: $0 receive <file> <dataset>"
            exit 1
        fi
        
        if [ ! -f "$INPUT_FILE" ]; then
            echo -e "${RED}✗ Input file not found: $INPUT_FILE${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}Importing dataset from file...${NC}"
        echo "Input: $INPUT_FILE"
        echo "Dataset: $DATASET"
        echo ""
        
        if "$ZFS_BIN_PATH/zfs" list "$DATASET" &>/dev/null; then
            echo -e "${YELLOW}⚠ WARNING: Dataset already exists${NC}"
            read -p "Destroy and recreate? (yes/no): " CONFIRM
            if [ "$CONFIRM" != "yes" ]; then
                echo "Import cancelled"
                exit 0
            fi
        fi
        
        echo "Receiving data..."
        if "$ZFS_BIN_PATH/zfs" receive -v "$DATASET" < "$INPUT_FILE"; then
            echo -e "${GREEN}✓ Import successful${NC}"
        else
            echo -e "${RED}✗ Import failed${NC}"
            exit 1
        fi
        ;;
        
    replicate)
        SRC_DATASET="$1"
        DST_DATASET="$2"
        
        if [ -z "$SRC_DATASET" ] || [ -z "$DST_DATASET" ]; then
            echo "Error: Source and destination datasets required"
            echo "Usage: $0 replicate <source> <destination>"
            exit 1
        fi
        
        echo -e "${BLUE}Replicating dataset...${NC}"
        echo "Source: $SRC_DATASET"
        echo "Destination: $DST_DATASET"
        echo ""
        
        # Create snapshot
        SNAPSHOT="${SRC_DATASET}@replicate-$(date '+%Y%m%d-%H%M%S')"
        echo "Creating snapshot: $SNAPSHOT"
        
        if ! "$ZFS_BIN_PATH/zfs" snapshot "$SNAPSHOT"; then
            echo -e "${RED}✗ Failed to create snapshot${NC}"
            exit 1
        fi
        
        # Replicate
        echo "Replicating..."
        if "$ZFS_BIN_PATH/zfs" send "$SNAPSHOT" | "$ZFS_BIN_PATH/zfs" receive -v "$DST_DATASET"; then
            echo -e "${GREEN}✓ Replication successful${NC}"
        else
            echo -e "${RED}✗ Replication failed${NC}"
            "$ZFS_BIN_PATH/zfs" destroy "$SNAPSHOT" 2>/dev/null || true
            exit 1
        fi
        ;;
        
    verify)
        INPUT_FILE="$1"
        
        if [ -z "$INPUT_FILE" ]; then
            echo "Error: Input file required"
            echo "Usage: $0 verify <file>"
            exit 1
        fi
        
        if [ ! -f "$INPUT_FILE" ]; then
            echo -e "${RED}✗ File not found: $INPUT_FILE${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}Verifying backup file...${NC}"
        echo "File: $INPUT_FILE"
        echo ""
        
        SIZE=$(du -h "$INPUT_FILE" | awk '{print $1}')
        echo "File size: $SIZE"
        
        # Try to read the stream without importing
        if "$ZFS_BIN_PATH/zfs" receive -nvF < "$INPUT_FILE" &>/dev/null; then
            echo -e "${GREEN}✓ Backup file is valid${NC}"
            echo ""
            echo "Stream details:"
            "$ZFS_BIN_PATH/zfs" receive -nvF < "$INPUT_FILE" | head -10
            exit 0
        else
            echo -e "${RED}✗ Backup file appears corrupted${NC}"
            exit 1
        fi
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
