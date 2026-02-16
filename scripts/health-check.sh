#!/bin/bash

###############################################################################
# Health Check Scheduler
# 
# Purpose: Run periodic health checks and alert on issues
# Usage: Run via cron or LaunchDaemon
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Defaults
POOL_NAME="${POOL_NAME:-media_pool}"
ZFS_BIN_PATH="${ZFS_BIN_PATH:-/usr/local/zfs/bin}"
LOG_FILE="${HEALTH_CHECK_LOG:-/var/log/zfs-health-check.log}"
CAPACITY_WARNING="${CAPACITY_WARNING:-70}"
CAPACITY_CRITICAL="${CAPACITY_CRITICAL:-85}"
ERROR_THRESHOLD="${ERROR_THRESHOLD:-1}"

# Logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Notification function
send_alert() {
    local severity="$1"
    local title="$2"
    local message="$3"
    
    # macOS notification
    if [ "${ENABLE_NOTIFICATIONS:-true}" = "true" ]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Basso\"" 2>/dev/null || true
    fi
    
    # Email notification
    if [ "${ENABLE_EMAIL:-false}" = "true" ] && [ -n "$EMAIL_ADDRESS" ]; then
        echo "$message" | mail -s "[ZFS-ALERT] $title" "$EMAIL_ADDRESS" 2>/dev/null || true
    fi
    
    log_message "$severity: $title - $message"
}

# Initialize
log_message "=========================================="
log_message "Starting ZFS Health Check"
log_message "=========================================="

# Check if ZFS is available
if [ ! -x "$ZFS_BIN_PATH/zpool" ]; then
    send_alert "CRITICAL" "ZFS Not Available" "ZFS binaries not found at $ZFS_BIN_PATH"
    exit 1
fi

# Check if pool exists
if ! "$ZFS_BIN_PATH/zpool" list "$POOL_NAME" &>/dev/null; then
    send_alert "CRITICAL" "Pool Not Found" "ZFS pool '$POOL_NAME' is not imported or does not exist"
    exit 1
fi

ALERTS_TRIGGERED=0

# ============================================================================
# Check 1: Pool Health
# ============================================================================

POOL_HEALTH=$("$ZFS_BIN_PATH/zpool" list -H -o health "$POOL_NAME")
log_message "Pool health: $POOL_HEALTH"

if [ "$POOL_HEALTH" != "ONLINE" ]; then
    send_alert "CRITICAL" "Pool Health Critical" \
        "Pool '$POOL_NAME' health is $POOL_HEALTH (not ONLINE). Immediate attention required!"
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
fi

# ============================================================================
# Check 2: Capacity
# ============================================================================

CAPACITY=$("$ZFS_BIN_PATH/zpool" list -H -o capacity "$POOL_NAME" | tr -d '%')
log_message "Pool capacity: ${CAPACITY}%"

if [ "$CAPACITY" -ge "$CAPACITY_CRITICAL" ]; then
    send_alert "CRITICAL" "Pool Capacity Critical" \
        "Pool '$POOL_NAME' is ${CAPACITY}% full (critical threshold: ${CAPACITY_CRITICAL}%). Running out of space!"
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
elif [ "$CAPACITY" -ge "$CAPACITY_WARNING" ]; then
    send_alert "WARNING" "Pool Capacity Warning" \
        "Pool '$POOL_NAME' is ${CAPACITY}% full (warning threshold: ${CAPACITY_WARNING}%). Consider freeing up space."
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
fi

# ============================================================================
# Check 3: Errors
# ============================================================================

READ_ERRORS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "errors:" | head -1 | awk '{print $NF}')
WRITE_ERRORS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "errors:" | tail -1 | awk '{print $NF}')

log_message "Read errors: $READ_ERRORS"
log_message "Write errors: $WRITE_ERRORS"

if [[ "$READ_ERRORS" =~ ^[0-9]+$ ]] && [ "$READ_ERRORS" -gt "$ERROR_THRESHOLD" ]; then
    send_alert "CRITICAL" "Read Errors Detected" \
        "Pool '$POOL_NAME' has $READ_ERRORS read errors. Data integrity may be compromised!"
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
fi

if [[ "$WRITE_ERRORS" =~ ^[0-9]+$ ]] && [ "$WRITE_ERRORS" -gt "$ERROR_THRESHOLD" ]; then
    send_alert "CRITICAL" "Write Errors Detected" \
        "Pool '$POOL_NAME' has $WRITE_ERRORS write errors. Check drives immediately!"
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
fi

# ============================================================================
# Check 4: Scrub Status
# ============================================================================

SCRUB_STATUS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "scan:")
log_message "Scrub status: $SCRUB_STATUS"

# Check if scrub is old (more than 35 days)
if echo "$SCRUB_STATUS" | grep -q "scrub repaired"; then
    DAYS_SINCE_SCRUB=$(echo "$SCRUB_STATUS" | grep -oE '[0-9]+ days' | head -1 | awk '{print $1}')
    
    if [ -n "$DAYS_SINCE_SCRUB" ] && [ "$DAYS_SINCE_SCRUB" -gt 35 ]; then
        send_alert "WARNING" "Scrub Overdue" \
            "Pool '$POOL_NAME' last scrubbed $DAYS_SINCE_SCRUB days ago. Monthly scrubs recommended."
        ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
    fi
elif echo "$SCRUB_STATUS" | grep -q "never scrubbed"; then
    send_alert "WARNING" "Never Scrubbed" \
        "Pool '$POOL_NAME' has never been scrubbed. Run scrub to verify data integrity."
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
fi

# ============================================================================
# Check 5: Encryption Keys
# ============================================================================

# Check if any encrypted datasets have unavailable keys
ENCRYPTED_DATASETS=$("$ZFS_BIN_PATH/zfs" get -H -o name,value encryption -r "$POOL_NAME" 2>/dev/null | grep -v "off" | awk '{print $1}')

if [ -n "$ENCRYPTED_DATASETS" ]; then
    log_message "Checking encryption keys..."
    
    while IFS= read -r dataset; do
        KEY_STATUS=$("$ZFS_BIN_PATH/zfs" get -H -o value keystatus "$dataset" 2>/dev/null)
        
        if [ "$KEY_STATUS" = "unavailable" ]; then
            send_alert "WARNING" "Encryption Key Unavailable" \
                "Dataset '$dataset' has unavailable encryption key. Dataset cannot be accessed!"
            ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
        fi
    done <<< "$ENCRYPTED_DATASETS"
fi

# ============================================================================
# Check 6: Mount Status
# ============================================================================

UNMOUNTED=$("$ZFS_BIN_PATH/zfs" get -H -o name,value mounted -r "$POOL_NAME" 2>/dev/null | grep "no" | wc -l | tr -d ' ')
log_message "Unmounted datasets: $UNMOUNTED"

if [ "$UNMOUNTED" -gt 0 ]; then
    UNMOUNTED_LIST=$("$ZFS_BIN_PATH/zfs" get -H -o name,value mounted -r "$POOL_NAME" 2>/dev/null | grep "no" | awk '{print $1}')
    
    send_alert "WARNING" "Unmounted Datasets" \
        "Found $UNMOUNTED unmounted datasets: $UNMOUNTED_LIST"
    ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
fi

# ============================================================================
# Check 7: Auto-Mount Service
# ============================================================================

if [ -f "/Library/LaunchDaemons/com.local.zfs.automount.plist" ]; then
    if ! launchctl list | grep -q "com.local.zfs.automount"; then
        send_alert "WARNING" "Auto-Mount Service Not Running" \
            "ZFS auto-mount LaunchDaemon is not loaded. Pool may not mount on boot!"
        ALERTS_TRIGGERED=$((ALERTS_TRIGGERED + 1))
    fi
fi

# ============================================================================
# Summary
# ============================================================================

log_message "=========================================="

if [ $ALERTS_TRIGGERED -eq 0 ]; then
    log_message "✓ Health check completed - No issues found"
    log_message "=========================================="
    
    # Optional success notification (off by default)
    if [ "${NOTIFY_HEALTH_CHECK_SUCCESS:-false}" = "true" ]; then
        send_alert "INFO" "Health Check Passed" \
            "All ZFS health checks passed for pool '$POOL_NAME'"
    fi
    
    exit 0
else
    log_message "⚠ Health check completed - $ALERTS_TRIGGERED alerts triggered"
    log_message "=========================================="
    exit 1
fi
