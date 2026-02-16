#!/bin/bash

###############################################################################
# ZFS Auto-Mount Script for macOS
# 
# Purpose: Automatically imports ZFS pool, loads encryption keys, and mounts
#          filesystems on boot
#
# Usage: Installed as LaunchDaemon, runs automatically at boot
#        Manual: sudo /usr/local/bin/zfs-automount.sh
#
# Author: macOS ZFS DAS Project
# License: MIT
# Repository: https://github.com/yourusername/macos-zfs-das
###############################################################################

# ============================================================================
# CONFIGURATION - LOAD FROM CONFIG FILE
# ============================================================================

# Try to load configuration from multiple locations
CONFIG_LOADED=false

for config_path in \
    "/usr/local/etc/zfs-das.conf" \
    "/etc/zfs-das.conf" \
    "$(dirname "$0")/../configs/zfs-das.conf" \
    "$HOME/.config/zfs-das.conf"; do
    
    if [ -f "$config_path" ]; then
        # shellcheck source=/dev/null
        source "$config_path"
        CONFIG_LOADED=true
        break
    fi
done

# Fallback to defaults if config not found
if [ "$CONFIG_LOADED" = false ]; then
    echo "WARNING: Config file not found, using defaults" >&2
    
    # Default configuration values
    POOL_NAME="media_pool"
    ZFS_BIN_PATH="/usr/local/zfs/bin"
    LOG_FILE="/var/log/zfs-automount.log"
    DAS_INIT_WAIT=10
    ENABLE_TIME_MACHINE=true
    TM_SPARSE_BUNDLE_NAME="MacMini-Backup.sparsebundle"
    TM_POOL_PATH="/Volumes/${POOL_NAME}/backups"
else
    # Use config file value or fallback to automount-specific log
    LOG_FILE="${AUTOMOUNT_LOG_FILE:-/var/log/zfs-automount.log}"
fi


# ============================================================================
# SCRIPT BEGINS - DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING
# ============================================================================

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "=========================================="
log_message "Starting ZFS auto-mount process"
log_message "=========================================="

# Wait for system to be ready (DAS drives may need time to initialize)
log_message "Waiting for system initialization (${DAS_INIT_WAIT} seconds)..."
sleep "$DAS_INIT_WAIT"
log_message "System ready, proceeding with pool import"

# ============================================================================
# STEP 1: Import ZFS Pool with Retry Logic
# ============================================================================

log_message "Importing ZFS pool: $POOL_NAME"

# Function to send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${NOTIFICATION_SOUND:-Basso}"
    
    if [ "${ENABLE_NOTIFICATIONS:-true}" = "true" ]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\"" 2>/dev/null || true
    fi
}

# Retry configuration from config file or defaults
RETRY_COUNT="${IMPORT_RETRY_COUNT:-3}"
RETRY_DELAY="${IMPORT_RETRY_DELAY:-5}"

# Try to import the pool with retry logic
IMPORT_SUCCESS=false
ATTEMPT=1

log_message "Starting pool import (max attempts: $RETRY_COUNT)..."

while [ $ATTEMPT -le $RETRY_COUNT ] && [ "$IMPORT_SUCCESS" = false ]; do
    if [ $ATTEMPT -gt 1 ]; then
        # Exponential backoff for retries
        WAIT_TIME=$((RETRY_DELAY * ATTEMPT))
        log_message "Retry attempt $ATTEMPT/$RETRY_COUNT after ${WAIT_TIME}s delay..."
        sleep $WAIT_TIME
    else
        log_message "Import attempt $ATTEMPT/$RETRY_COUNT..."
    fi
    
    # Try importing the pool
    # -d /dev scans all devices to find the pool
    # This is necessary because pool cache may not be up to date
    if "$ZFS_BIN_PATH/zpool" import -d /dev "$POOL_NAME" >> "$LOG_FILE" 2>&1; then
        IMPORT_SUCCESS=true
        log_message "✓ Pool imported successfully on attempt $ATTEMPT"
    else
        log_message "⚠ Import attempt $ATTEMPT failed"
        
        # If this was the last attempt, try force import
        if [ $ATTEMPT -eq $RETRY_COUNT ]; then
            log_message "⚠ All regular import attempts failed, trying force import..."
            
            if "$ZFS_BIN_PATH/zpool" import -d /dev -f "$POOL_NAME" >> "$LOG_FILE" 2>&1; then
                IMPORT_SUCCESS=true
                log_message "✓ Force import succeeded"
                send_notification "ZFS Auto-Mount Warning" \
                    "Pool imported using force flag. Check for issues."
            else
                log_message "✗ FATAL: Could not import pool $POOL_NAME"
                log_message "Check that DAS is connected and drives are visible"
                
                # Send notification about failure
                send_notification "ZFS Auto-Mount Failed" \
                    "Could not import pool $POOL_NAME. Check system logs."
                
                exit 1
            fi
        fi
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

if [ "$IMPORT_SUCCESS" = false ]; then
    log_message "✗ FATAL: Failed to import pool after $RETRY_COUNT attempts"
    send_notification "ZFS Auto-Mount Failed" \
        "Pool import failed after $RETRY_COUNT attempts"
    exit 1
fi

# Verify pool state
POOL_STATE=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "state:" | awk '{print $2}')
log_message "Pool state: $POOL_STATE"

if [ "$POOL_STATE" != "ONLINE" ]; then
    log_message "⚠ WARNING: Pool is in $POOL_STATE state (expected ONLINE)"
fi

# ============================================================================
# STEP 2: Load Encryption Keys
# ============================================================================

log_message "Loading encryption keys for encrypted datasets..."

# Validate key directory permissions if it exists
KEY_DIR="${KEY_DIR:-/etc/zfs/keys}"
SECURITY_WARNINGS=0

if [ -d "$KEY_DIR" ]; then
    log_message "Validating key directory security..."
    
    # Check directory permissions (should be 700)
    DIR_PERMS=$(stat -f "%Lp" "$KEY_DIR" 2>/dev/null || stat -c "%a" "$KEY_DIR" 2>/dev/null)
    if [ "$DIR_PERMS" != "700" ]; then
        log_message "⚠ WARNING: Key directory has insecure permissions: $DIR_PERMS (should be 700)"
        SECURITY_WARNINGS=$((SECURITY_WARNINGS + 1))
        
        # Attempt to fix if running as root
        if [ "$EUID" -eq 0 ]; then
            chmod 700 "$KEY_DIR" 2>/dev/null && log_message "✓ Fixed directory permissions to 700"
        fi
    fi
    
    # Check directory ownership (should be root)
    DIR_OWNER=$(stat -f "%Su" "$KEY_DIR" 2>/dev/null || stat -c "%U" "$KEY_DIR" 2>/dev/null)
    if [ "$DIR_OWNER" != "root" ]; then
        log_message "⚠ WARNING: Key directory not owned by root (owner: $DIR_OWNER)"
        SECURITY_WARNINGS=$((SECURITY_WARNINGS + 1))
    fi
    
    # Validate individual key files
    for keyfile in "$KEY_DIR"/*.key 2>/dev/null; do
        if [ -f "$keyfile" ]; then
            # Check file permissions (should be 600)
            KEY_PERMS=$(stat -f "%Lp" "$keyfile" 2>/dev/null || stat -c "%a" "$keyfile" 2>/dev/null)
            if [ "$KEY_PERMS" != "600" ]; then
                log_message "⚠ WARNING: Key file has insecure permissions: $(basename "$keyfile") ($KEY_PERMS, should be 600)"
                SECURITY_WARNINGS=$((SECURITY_WARNINGS + 1))
                
                # Attempt to fix if running as root
                if [ "$EUID" -eq 0 ]; then
                    chmod 600 "$keyfile" 2>/dev/null && log_message "✓ Fixed permissions for $(basename "$keyfile")"
                fi
            fi
            
            # Check file ownership
            KEY_OWNER=$(stat -f "%Su" "$keyfile" 2>/dev/null || stat -c "%U" "$keyfile" 2>/dev/null)
            if [ "$KEY_OWNER" != "root" ]; then
                log_message "⚠ WARNING: Key file not owned by root: $(basename "$keyfile") (owner: $KEY_OWNER)"
                SECURITY_WARNINGS=$((SECURITY_WARNINGS + 1))
            fi
            
            # Check if key is world-readable
            if [ -r "$keyfile" ] && [ "$(stat -f "%A" "$keyfile" | cut -c9)" != "-" ] 2>/dev/null; then
                log_message "⚠ CRITICAL: Key file is world-readable: $(basename "$keyfile")"
                SECURITY_WARNINGS=$((SECURITY_WARNINGS + 1))
            fi
        fi
    done
    
    if [ $SECURITY_WARNINGS -gt 0 ]; then
        log_message "⚠ Found $SECURITY_WARNINGS security warning(s) for encryption keys"
        send_notification "ZFS Encryption Security Warning" \
            "Found $SECURITY_WARNINGS security issues with encryption keys. Check logs."
    else
        log_message "✓ Key directory and files have correct permissions"
    fi
fi

# Attempt to load all keys
# Keys should be stored in /etc/zfs/keys/ for automatic loading
# See docs/ENCRYPTION.md for key setup instructions
if "$ZFS_BIN_PATH/zfs" load-key -a >> "$LOG_FILE" 2>&1; then
    log_message "✓ All encryption keys loaded successfully"
else
    log_message "⚠ WARNING: Some keys may not have loaded automatically"
    log_message "If datasets are encrypted, they may not mount"
    log_message "Check /etc/zfs/keys/ for key files"
    
    send_notification "ZFS Encryption Warning" \
        "Some encryption keys failed to load. Datasets may not mount."
fi

# ============================================================================
# STEP 3: Mount All ZFS Filesystems
# ============================================================================

log_message "Mounting all ZFS filesystems..."

"$ZFS_BIN_PATH/zfs" mount -a >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log_message "✓ All filesystems mounted successfully"
else
    log_message "⚠ WARNING: Some filesystems may not have mounted"
    log_message "Check encryption keys or filesystem properties"
fi

# Count mounted datasets
MOUNTED_COUNT=$("$ZFS_BIN_PATH/zfs" list -H | wc -l | tr -d ' ')
log_message "Mounted datasets: $MOUNTED_COUNT"

# ============================================================================
# STEP 4: Mount Time Machine Sparse Bundle (Optional)
# ============================================================================

if [ "$ENABLE_TIME_MACHINE" = true ]; then
    log_message "Mounting Time Machine sparse bundle..."
    
    SPARSE_BUNDLE_PATH="$TM_POOL_PATH/$TM_SPARSE_BUNDLE_NAME"
    
    if [ -e "$SPARSE_BUNDLE_PATH" ]; then
        /usr/bin/hdiutil attach "$SPARSE_BUNDLE_PATH" >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            log_message "✓ Time Machine sparse bundle mounted successfully"
        else
            log_message "⚠ WARNING: Failed to mount Time Machine sparse bundle"
            log_message "Path: $SPARSE_BUNDLE_PATH"
        fi
    else
        log_message "⚠ WARNING: Time Machine sparse bundle not found"
        log_message "Expected path: $SPARSE_BUNDLE_PATH"
        log_message "Set ENABLE_TIME_MACHINE=false if not using Time Machine"
    fi
else
    log_message "Time Machine auto-mount disabled (ENABLE_TIME_MACHINE=false)"
fi

# ============================================================================
# AUTO-MOUNT COMPLETE
# ============================================================================

log_message "=========================================="
log_message "ZFS Auto-Mount Complete"
log_message "=========================================="

# Get final pool status
POOL_HEALTH=$("$ZFS_BIN_PATH/zpool" list -H -o health "$POOL_NAME" 2>/dev/null || echo "UNKNOWN")
MOUNTED_COUNT=$("$ZFS_BIN_PATH/zfs" list -H -o name,mounted -r "$POOL_NAME" 2>/dev/null | grep -c "yes" || echo "0")

log_message "Pool health: $POOL_HEALTH"
log_message "Datasets mounted: $MOUNTED_COUNT"

# Send success notification
if [ "$POOL_HEALTH" = "ONLINE" ] && [ "$MOUNTED_COUNT" -gt 0 ]; then
    log_message "✓ All operations completed successfully"
    
    # Only send success notification if enabled in config
    if [ "${NOTIFY_ON_SUCCESS:-false}" = "true" ]; then
        send_notification "ZFS Auto-Mount Success" \
            "Pool '$POOL_NAME' mounted successfully ($MOUNTED_COUNT datasets)"
    fi
    
    exit 0
else
    log_message "⚠ Completed with warnings"
    send_notification "ZFS Auto-Mount Warning" \
        "Pool mounted but check logs for warnings"
    
    exit 0  # Exit 0 so LaunchDaemon doesn't retry
fi
# Log final pool list
log_message "Final pool and dataset list:"
"$ZFS_BIN_PATH/zfs" list >> "$LOG_FILE" 2>&1

# Check for any errors in pool
POOL_ERRORS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep -i "errors:" | grep -v "No known data errors")
if [ -n "$POOL_ERRORS" ]; then
    log_message "⚠ WARNING: Pool has errors:"
    log_message "$POOL_ERRORS"
else
    log_message "✓ Pool health: No errors detected"
fi

log_message "Auto-mount script finished"
exit 0

###############################################################################
# TROUBLESHOOTING
# ============================================================================
# 
# If pool doesn't import automatically:
# 1. Check this log: /var/log/zfs-automount.log
# 2. Verify DAS is connected: diskutil list
# 3. Check OpenZFS is loaded: kextstat | grep zfs
# 4. Try manual import: sudo zpool import -d /dev
#
# If encryption keys don't load:
# 1. Verify keys exist: ls -la /etc/zfs/keys/
# 2. Check key permissions: should be 600, owned by root
# 3. Verify keylocation property: zfs get keylocation
# 4. See docs/ENCRYPTION.md for key setup
#
# If Time Machine doesn't mount:
# 1. Check sparse bundle exists at configured path
# 2. Verify sparse bundle isn't corrupted: diskutil verifyVolume
# 3. Check Time Machine destination: tmutil destinationinfo
# 4. See docs/TIME_MACHINE.md for setup
#
###############################################################################

