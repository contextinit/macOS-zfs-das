#!/bin/bash

###############################################################################
# ZFS Monthly Maintenance Script
# 
# Purpose: Automated pool scrubbing, health checks, and reporting
# Schedule: Run on 1st of each month at 1 AM via LaunchDaemon
#
# Author: macOS ZFS DAS Project
# License: MIT
# Schedule: Run on 1st of each month at 1 AM via LaunchDaemon
#
# Author: macOS ZFS DAS Project
# License: MIT
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
    
    ZFS_BIN_PATH="/usr/local/zfs/bin"
    POOL_NAME="media_pool"
    LOG_FILE="/var/log/zfs-maintenance.log"
    ENABLE_EMAIL=false
    EMAIL_ADDRESS="you@example.com"
else
    # Use config file value or fallback
    LOG_FILE="${MAINTENANCE_LOG_FILE:-/var/log/zfs-maintenance.log}"
fi

# ============================================================================
# FUNCTIONS
# ============================================================================

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Email notification function
send_email() {
    local subject="$1"
    local body="$2"
    
    if [ "$ENABLE_EMAIL" != "true" ]; then
        return
    fi
    
    if [ -z "$EMAIL_ADDRESS" ]; then
        log_message "⚠ Email enabled but EMAIL_ADDRESS not set"
        return
    fi
    
    # Try to send email using mail command (available on macOS)
    if command -v mail &>/dev/null; then
        echo "$body" | mail -s "${EMAIL_SUBJECT_PREFIX:-[ZFS-DAS]} $subject" "$EMAIL_ADDRESS" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "✓ Email sent to $EMAIL_ADDRESS"
        else
            log_message "⚠ Failed to send email"
        fi
    else
        log_message "⚠ mail command not found, cannot send email"
        log_message "  Install mail utilities or disable email notifications"
    fi
}

# ============================================================================
# MAINTENANCE START
# ============================================================================

log_message "=========================================="
log_message "Starting ZFS Monthly Maintenance"
log_message "=========================================="

# Stop Time Machine backups during maintenance
log_message "Step 1: Stopping Time Machine backups..."
/usr/bin/tmutil stopbackup 2>&1 | tee -a "$LOG_FILE"
sleep 10

# Disable Spotlight indexing
log_message "Step 2: Disabling Spotlight indexing..."
/usr/bin/mdutil -i off "/Volumes/${POOL_NAME}" 2>&1 | tee -a "$LOG_FILE"

# Pre-scrub health check
log_message "Step 3: Pre-scrub health check..."
"$ZFS_BIN_PATH/zpool" status "$POOL_NAME" 2>&1 | tee -a "$LOG_FILE"

# Check for existing errors
PRE_ERRORS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep -i "errors:" | grep -v "No known data errors")
if [ -n "$PRE_ERRORS" ]; then
    log_message "⚠ WARNING: Pre-existing errors detected!"
fi

# Start scrub
log_message "Step 4: Starting ZFS scrub..."
"$ZFS_BIN_PATH/zpool" scrub "$POOL_NAME" 2>&1 | tee -a "$LOG_FILE"

# Monitor scrub progress
log_message "Step 5: Monitoring scrub progress..."
SCRUB_COMPLETE=false
CHECK_COUNT=0
MAX_CHECKS=${SCRUB_TIMEOUT:-288}  # Default 24 hours (288 * 5 minutes)

while [ "$SCRUB_COMPLETE" = false ] && [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    sleep 300  # Check every 5 minutes
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    SCRUB_STATUS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep "scan:")
    
    if ! echo "$SCRUB_STATUS" | grep -q "scrub in progress"; then
        SCRUB_COMPLETE=true
        log_message "✓ Scrub completed after $(($CHECK_COUNT * 5)) minutes"
    else
        # Log progress periodically (every hour)
        if [ $((CHECK_COUNT % 12)) -eq 0 ]; then
            PROGRESS=$(echo "$SCRUB_STATUS" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
            log_message "Scrub in progress: ${PROGRESS:-checking...}"
        fi
    fi
done

# Check if scrub timed out
if [ "$SCRUB_COMPLETE" = false ]; then
    log_message "⚠ WARNING: Scrub timeout reached after $((MAX_CHECKS * 5)) minutes"
    log_message "Scrub is still running in background"
    
    send_email "ZFS Scrub Timeout Warning" \
        "Pool: $POOL_NAME

Scrub has been running for more than $((MAX_CHECKS * 5)) minutes and is still in progress.

This may indicate a very large pool or potential issues.

Current status:
$SCRUB_STATUS

Please check pool status manually."
fi

# Post-scrub health check
log_message "Step 6: Post-scrub health check..."
"$ZFS_BIN_PATH/zpool" status -v "$POOL_NAME" 2>&1 | tee -a "$LOG_FILE"

# Generate report
log_message "Step 7: Generating health report..."
"$ZFS_BIN_PATH/zpool" list "$POOL_NAME" 2>&1 | tee -a "$LOG_FILE"
"$ZFS_BIN_PATH/zfs" list 2>&1 | tee -a "$LOG_FILE"

# Re-enable Spotlight
log_message "Step 8: Re-enabling Spotlight..."
/usr/bin/mdutil -i on "/Volumes/${POOL_NAME}" 2>&1 | tee -a "$LOG_FILE"

# Run post-maintenance hook if exists
POST_HOOK="${MAINTENANCE_POST_HOOK:-/usr/local/bin/post-maintenance-hook.sh}"
if [ -x "$POST_HOOK" ]; then
    log_message "Running post-maintenance hook: $POST_HOOK"
    if "$POST_HOOK" >> "$LOG_FILE" 2>&1; then
        log_message "✓ Post-maintenance hook completed"
    else
        log_message "⚠ WARNING: Post-maintenance hook failed"
    fi
fi

# Check for errors and send email report
POST_ERRORS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME" | grep -i "errors:" | grep -v "No known data errors")

log_message "=========================================="
log_message "Monthly Maintenance Complete"
log_message "=========================================="

# Send email summary
if [ "$ENABLE_EMAIL" = "true" ]; then
    POOL_STATUS=$("$ZFS_BIN_PATH/zpool" status "$POOL_NAME")
    POOL_LIST=$("$ZFS_BIN_PATH/zpool" list "$POOL_NAME")

    EMAIL_BODY="ZFS Monthly Maintenance completed for pool: $POOL_NAME

Maintenance Summary:
- Scrub: Completed
- Duration: $(($CHECK_COUNT * 5)) minutes
- Pool State: $(echo "$POOL_STATUS" | grep "state:" | awk '{print $2}')

Pool Status:
$POOL_STATUS

Pool Capacity:
$POOL_LIST

"
    
    if [ -n "$POST_ERRORS" ]; then
        EMAIL_BODY="$EMAIL_BODY
⚠ WARNING: Errors detected:
$POST_ERRORS

Please investigate immediately.
"
        send_email "ZFS Maintenance Complete - ERRORS FOUND" "$EMAIL_BODY"
    else
        EMAIL_BODY="$EMAIL_BODY
✓ No errors detected - pool is healthy
"
        send_email "ZFS Maintenance Complete - Healthy" "$EMAIL_BODY"
    fi
fi

exit 0
