# User Experience Improvements

## Overview

This document outlines user experience improvements for better feedback, status checking, and error handling.

## Tools

### 1. Status Check Utility

**Script:** `scripts/check-zfs-status.sh`

**Usage:**
```bash
# Check default pool from config
./scripts/check-zfs-status.sh

# Check specific pool
./scripts/check-zfs-status.sh my_pool
```

**Features:**
- Color-coded output for quick status assessment
- Pool health check (ONLINE, DEGRADED, etc.)
- Capacity warnings (70%, 85% thresholds)
- Error detection
- Scrub status with progress
- Dataset list with encryption status
- Auto-mount service status
- Overall system health summary

**Example Output:**
```
╔═══════════════════════════════════════╗
║   ZFS Status Check                    ║
╚═══════════════════════════════════════╝

✓ ZFS installed

Checking pool: media_pool
-------------------------------------------
Health: ✓ ONLINE
Capacity: 45%
Size: 10T
Used: 4.5T | Free: 5.5T

Error Check
-------------------------------------------
✓ No errors detected

Scrub Status
-------------------------------------------
✓ Last scrub: completed on Sun Dec 1 01:00:00 2024

Datasets
-------------------------------------------
Name                          Mounted  Encrypted  Size
media_pool                    ✓ yes     -    off       96K
data                          ✓ yes     🔒   aes-256   4.5T
backups                       ✓ yes     🔒   aes-256   2.1T

Auto-Mount Service
-------------------------------------------
✓ Service loaded
Last run: 2024-12-13 16:00:00

╔═══════════════════════════════════════╗
║   Overall Status                      ║
╚═══════════════════════════════════════╝

✓ All systems healthy

Your ZFS pool is operating normally.
```

---

## Notifications

### macOS Notification System

All scripts now support native macOS notifications using `osascript`.

**Configuration:**
```bash
# In configs/zfs-das.conf
ENABLE_NOTIFICATIONS=true
NOTIFICATION_SOUND="Basso"  # or "Ping", "Glass", etc.
NOTIFY_ON_SUCCESS=false     # Set to true for success notifications
```

**Notification Types:**

1. **Critical Failures** (always sent)
   - Pool import failed
   - Encryption key loading failed
   - Security issues detected

2. **Warnings** (always sent)
   - Force import used
   - Some keys failed to load
   - Security warnings found

3. **Success** (optional, off by default)
   - Pool mounted successfully
   - All operations complete

**Example Notifications:**
```
Title: "ZFS Auto-Mount Success"
Message: "Pool 'media_pool' mounted successfully (3 datasets)"
Sound: Basso

Title: "ZFS Auto-Mount Failed"
Message: "Could not import pool media_pool. Check system logs."
Sound: Basso

Title: "ZFS Encryption Security Warning"
Message: "Found 2 security issues with encryption keys. Check logs."
Sound: Basso
```

---

## LaunchDaemon Configuration

### Intelligent Retry

**File:** `configs/launchd/com.local.zfs.automount.plist`

**Key Configuration:**
```xml
<!-- Intelligent retry: only restart if script exits with error -->
<key>KeepAlive</key>
<dict>
    <key>SuccessfulExit</key>
    <false/>
</dict>

<!-- Throttle restart attempts to avoid rapid cycling -->
<key>ThrottleInterval</key>
<integer>60</integer>
```

**Behavior:**
- Script exits with 0 (success) → LaunchDaemon does NOT restart
- Script exits with 1 (error) → LaunchDaemon restarts after 60 seconds
- Maximum restart attempts controlled by system
- Prevents rapid cycling on persistent failures

**Benefits:**
- Automatic recovery from transient failures
- DAS connection delays handled gracefully
- No rapid retry loops consuming resources
- Success doesn't trigger unnecessary restarts

---

## Progress Feedback

### Log File Monitoring

**Real-time Monitoring:**
```bash
# Watch automount log
tail -f /var/log/zfs-automount.log

# Watch maintenance log
tail -f /var/log/zfs-maintenance.log

# Filter for errors
tail -f /var/log/zfs-automount.log | grep "ERROR\|FATAL\|✗"

# Filter for warnings
tail -f /var/log/zfs-automount.log | grep "WARNING\|⚠"
```

**Log Format:**
```
2024-12-13 16:00:01 - ==========================================
2024-12-13 16:00:01 - Starting ZFS Auto-Mount
2024-12-13 16:00:01 - ==========================================
2024-12-13 16:00:01 - System ready, proceeding with pool import
2024-12-13 16:00:01 - Importing ZFS pool: media_pool
2024-12-13 16:00:01 - Starting pool import (max attempts: 3)...
2024-12-13 16:00:01 - Import attempt 1/3...
2024-12-13 16:00:02 - ✓ Pool imported successfully on attempt 1
2024-12-13 16:00:02 - Pool state: ONLINE
2024-12-13 16:00:02 - Loading encryption keys for encrypted datasets...
2024-12-13 16:00:02 - Validating key directory security...
2024-12-13 16:00:02 - ✓ Key directory and files have correct permissions
2024-12-13 16:00:02 - ✓ All encryption keys loaded successfully
2024-12-13 16:00:02 - Mounting all ZFS filesystems...
2024-12-13 16:00:03 - ✓ All filesystems mounted successfully
2024-12-13 16:00:03 - ==========================================
2024-12-13 16:00:03 - ZFS Auto-Mount Complete
2024-12-13 16:00:03 - ==========================================
2024-12-13 16:00:03 - Pool health: ONLINE
2024-12-13 16:00:03 - Datasets mounted: 3
2024-12-13 16:00:03 - ✓ All operations completed successfully
```

### Progress Indicators

**Import Progress:**
```
Starting pool import (max attempts: 3)...
Import attempt 1/3...
✓ Pool imported successfully on attempt 1
```

**Retry Progress:**
```
Import attempt 1/3...
⚠ Import attempt 1 failed
Retry attempt 2/3 after 10s delay...
Import attempt 2/3...
✓ Pool imported successfully on attempt 2
```

**Scrub Progress (Maintenance):**
```
Scrub in progress: 25.4%
Scrub in progress: 50.8%
Scrub in progress: 75.2%
✓ Scrub completed after 45 minutes
```

**Security Validation Progress:**
```
Validating key directory security...
✓ Key directory and files have correct permissions

# Or with issues:
Validating key directory security...
⚠ WARNING: Key file has insecure permissions: data.key (644, should be 600)
✓ Fixed permissions for data.key
⚠ Found 1 security warning(s) for encryption keys
```

---

## Error Messages

### Improved Error Clarity

**Before:**
```
ERROR: Pool import failed
```

**After:**
```
✗ FATAL: Could not import pool media_pool
Check that DAS is connected and drives are visible
[macOS Notification sent]
```

**Before:**
```
WARNING: Keys not loaded
```

**After:**
```
⚠ WARNING: Some keys may not have loaded automatically
If datasets are encrypted, they may not mount
Check /etc/zfs/keys/ for key files
[macOS Notification sent if encryption configured]
```

---

## Quick Commands

### User-Friendly Commands

Create aliases for common tasks:

```bash
# Add to ~/.zshrc or ~/.bashrc

# Check ZFS status
alias zfs-status='sudo /path/to/check-zfs-status.sh'

# View logs
alias zfs-log='tail -f /var/log/zfs-automount.log'

# Security audit
alias zfs-security='sudo /path/to/security-audit.sh'

# Restart auto-mount
alias zfs-restart='sudo launchctl kickstart -k system/com.local.zfs.automount'

# Check pool health
alias zfs-health='zpool status'
```

**Usage:**
```bash
zfs-status     # Check overall status
zfs-log        # Watch realtime logs
zfs-security   # Run security audit
zfs-restart    # Restart if needed
zfs-health     # Quick health check
```

---

## Best Practices

### For Users

1. **Check Status Regularly**
   ```bash
   ./scripts/check-zfs-status.sh
   ```

2. **Monitor Notifications**
   - Enable notifications in config
   - Review notification center after boot
   - Investigate any warnings immediately

3. **Review Logs After Boot**
   ```bash
   tail -50 /var/log/zfs-automount.log
   ```

4. **Run Security Audits**
   ```bash
   sudo ./scripts/security-audit.sh
   ```

5. **Set Up Monitoring**
   - Use SwiftBar for menu bar status
   - Get visual feedback without terminal

### For Administrators

1. **Test LaunchDaemon Behavior**
   ```bash
   # Unload service
   sudo launchctl unload /Library/LaunchDaemons/com.local.zfs.automount.plist
   
   # Test script manually
   sudo /usr/local/bin/zfs-automount.sh
   
   # Check exit code
   echo $?
   
   # Reload service
   sudo launchctl load /Library/LaunchDaemons/com.local.zfs.automount.plist
   ```

2. **Monitor LaunchDaemon Status**
   ```bash
   # Check if running
   sudo launchctl list | grep zfs
   
   # View service info
   sudo launchctl print system/com.local.zfs.automount
   ```

3. **Configure Notification Preferences**
   - Test with `NOTIFY_ON_SUCCESS=true`
   - Adjust for your monitoring needs
   - Balance information vs. noise

---

## Troubleshooting

### No Notifications Appearing

1. Check System Preferences → Notifications
2. Ensure Script Editor or Terminal has notification permissions
3. Test manually:
   ```bash
   osascript -e 'display notification "Test" with title "ZFS Test"'
   ```

### LaunchDaemon Not Restarting

1. Check exit code in logs
2. Verify `SuccessfulExit` is set to `false`
3. Check system logs:
   ```bash
   log show --predicate 'subsystem == "com.apple.launchd"' --last 1h | grep zfs
   ```

### Status Check Shows Wrong Pool

1. Specify pool name:
   ```bash
   ./scripts/check-zfs-status.sh correct_pool_name
   ```

2. Update config file with correct `POOL_NAME`

---

## Future Enhancements

Potential UX improvements for future versions:

1. **Web Dashboard**
   - Browser-based status monitoring
   - Interactive controls
   - Historical graphs

2. **Email Reports**
   - Daily/weekly status emails
   - Alert emails for issues
   - Maintenance completion reports

3. **Slack/Discord Integration**
   - Post status to team channels
   - Alert on issues
   - Maintenance notifications

4. **iOS/macOS App**
   - Native application for monitoring
   - Push notifications
   - Remote management

5. **Prometheus Metrics**
   - Export metrics for Grafana
   - Long-term trending
   - Advanced alerting

---

## Summary

**UX Improvements Implemented:**
- ✅ Color-coded status check utility
- ✅ Native macOS notifications
- ✅ Intelligent LaunchDaemon retry
- ✅ Detailed progress logging
- ✅ Clear error messages
- ✅ Security feedback
- ✅ Success/warning/error notifications

**Result:** Users now have complete visibility into ZFS operations with minimal effort!
