# Maintenance Guide

## Overview

Comprehensive guide to ZFS maintenance operations including automated scheduling, manual triggers, and best practices.

## Automated Maintenance

### Monthly Maintenance Script

**Script:** [scripts/zfs-maintenance.sh](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/scripts/zfs-maintenance.sh)

**What It Does:**

1. **Pre-Maintenance Validation**
   - Verifies pool exists
   - Checks pool health (must be ONLINE or DEGRADED)
   - Validates available space
   - Runs pre-maintenance hook (if configured)

2. **Disable Spotlight** (temporary)
   - Prevents Spotlight interference during scrub
   - Re-enabled after completion

3. **Trim SSD** (if applicable)
   - Reclaims deleted blocks
   - Improves SSD performance

4. **Start Scrub**
   - Verifies all data checksums
   - Repairs any corruption found
   - Comprehensive data integrity check

5. **Monitor Progress**
   - Checks every 5 minutes
   - Logs progress hourly
   - Detects scrub completion or timeout

6. **Health Check**
   - Post-scrub verification
   - Error detection
   - Capacity reporting

7. **Generate Report**
   - Pool status
   - Dataset list
   - Any errors found

8. **Post-Maintenance Tasks**
   - Re-enable Spotlight
   - Run post-maintenance hook (if configured)
   - Send email report (if configured)

---

### Automated Scheduling

**LaunchDaemon:** [com.local.zfs.maintenance.plist](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/configs/launchd/com.local.zfs.maintenance.plist)

**Schedule:** First day of every month at 2:00 AM

**Installation:**
```bash
# Copy maintenance script
sudo cp scripts/zfs-maintenance.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/zfs-maintenance.sh

# Install LaunchDaemon
sudo cp configs/launchd/com.local.zfs.maintenance.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.local.zfs.maintenance.plist
```

**Verify Installation:**
```bash
# Check if loaded
sudo launchctl list | grep maintenance

# View configuration
sudo launchctl print system/com.local.zfs.maintenance

# Check next run time
sudo launchctl print system/com.local.zfs.maintenance | grep NextRunTime
```

**Configuration:**
```xml
<!-- Run on 1st day of every month at 2:00 AM -->
<key>StartCalendarInterval</key>
<dict>
    <key>Day</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>2</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>

<!-- Low priority to not interfere with system -->
<key>Nice</key>
<integer>15</integer>
```

**Why 2:00 AM?**
- Minimal user activity
- Most systems awake (desktops)
- Completes before morning use
- Standard maintenance window

---

## Manual Maintenance

### Manual Scrub Trigger

**Script:** [scripts/trigger-scrub.sh](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/scripts/trigger-scrub.sh)

**Usage:**
```bash
# Interactive mode
sudo ./scripts/trigger-scrub.sh

# Specify pool
sudo ./scripts/trigger-scrub.sh media_pool

# Non-interactive (immediate start)
sudo ./scripts/trigger-scrub.sh media_pool --now
```

**Example Output:**
```
╔═══════════════════════════════════════╗
║   ZFS Scrub Trigger                   ║
╚═══════════════════════════════════════╝

Checking current scrub status...
scan: scrub repaired 0B in 02:15:33 completed on Sun Dec  1 04:16:00 2024

Pool health: ONLINE
Pool size: 10T

Estimated scrub time:
  Small pool (< 1TB):   1-2 hours
  Medium pool (1-5TB):  3-8 hours
  Large pool (5-10TB):  8-24 hours
  Huge pool (> 10TB):   24+ hours

Start scrub now? (yes/no): yes

Starting scrub...
✓ Scrub initiated successfully

You can monitor progress with:
  watch 'zpool status media_pool | grep scan'

The scrub will run in the background.
```

**Features:**
- Checks for existing scrub
- Option to cancel running scrub
- Pool health warning
- Time estimates
- Safety confirmations

---

## Maintenance Hooks

### Pre-Maintenance Hook

**Purpose:** Run custom tasks before maintenance starts

**Location:** `/usr/local/bin/pre-maintenance-hook.sh` (configurable)

**Example Use Cases:**
- Create snapshot before scrub
- Stop resource-intensive services
- Send notification to users
- Backup current state

**Example Script:**
```bash
#!/bin/bash
# Pre-maintenance hook example

# Create safety snapshot
zfs snapshot media_pool/data@pre-scrub-$(date +%Y%m%d)

# Stop Plex (example)
# launchctl stop com.plexapp.mediaserver

# Send notification
osascript -e 'display notification "ZFS maintenance starting" with title "System Maintenance"'

exit 0  # Must exit 0 to allow maintenance to proceed
```

**Configuration:**
```bash
# In configs/zfs-das.conf
MAINTENANCE_PRE_HOOK="/usr/local/bin/pre-maintenance-hook.sh"
```

---

### Post-Maintenance Hook

**Purpose:** Run custom tasks after maintenance completes

**Location:** `/usr/local/bin/post-maintenance-hook.sh` (configurable)

**Example Use Cases:**
- Clean up old snapshots
- Restart services
- Generate custom reports
- Update monitoring dashboards

**Example Script:**
```bash
#!/bin/bash
# Post-maintenance hook example

# Clean up old pre-scrub snapshots (keep last 3)
zfs list -t snapshot | grep pre-scrub | head -n -3 | awk '{print $1}' | xargs -n1 zfs destroy

# Restart Plex (example)
# launchctl start com.plexapp.mediaserver

# Send completion notification
osascript -e 'display notification "ZFS maintenance completed" with title "System Maintenance"'

exit 0
```

**Configuration:**
```bash
# In configs/zfs-das.conf
MAINTENANCE_POST_HOOK="/usr/local/bin/post-maintenance-hook.sh"
```

---

## Maintenance Best Practices

### Timing

**Recommended Schedule:**
- **Scrub:** Monthly (1st of month)
- **Health Check:** Every 6 hours
- **Trim:** Monthly (part of maintenance)
- **Snapshots:** Before risky operations

**Custom Schedules:**

For critical data (more frequent):
```bash
# Run scrub bi-weekly
# Modify LaunchDaemon StartCalendarInterval to include day 15
```

For archived data (less frequent):
```bash
# Run scrub quarterly
# Modify to run on specific months: 1, 4, 7, 10
```

---

### Monitoring Active Scrub

**Real-time Monitoring:**
```bash
# Watch scrub progress (updates every 2 seconds)
watch -n 2 'zpool status media_pool | grep -A 2 scan'

# One-time check
zpool status media_pool | grep scan

# Detailed status
zpool status -v media_pool
```

**Output During Scrub:**
```
scan: scrub in progress since Wed Dec 13 02:00:00 2024
    4.5T scanned at 500M/s, 2.3T issued at 250M/s
    0B repaired, 50.00% done, 02:30:00 to go
```

**Understanding Output:**
- **Scanned:** Data read and verified
- **Issued:** Data checked against checksums
- **Repaired:** Corrupted data fixed
- **% done:** Progress
- **To go:** Estimated time remaining

---

### Pre-Maintenance Checklist

Before starting maintenance:

- [ ] Verify adequate free space (< 95% full)
- [ ] Check pool is ONLINE or DEGRADED (not FAULTED)
- [ ] Ensure no critical operations in progress
- [ ] Verify backups are current
- [ ] Check system will remain powered on
- [ ] Review recent health check logs
- [ ] Confirm email notifications configured (optional)

---

### Post-Maintenance Review

After maintenance completes:

```bash
# 1. Check completion
tail -100 /var/log/zfs-maintenance.log

# 2. Review errors (if any)
zpool status -v media_pool

# 3. Check pool health
./scripts/check-zfs-status.sh

# 4. Verify Spotlight re-enabled
mdutil -s /Volumes/media_pool

# 5. Check email report (if configured)
```

---

## Troubleshooting

### Scrub Takes Too Long

**Symptoms:** Scrub running > 48 hours

**Solutions:**
1. Check if pool is under heavy load (reduces scrub priority)
2. Verify no hardware issues (slow drives)
3. Consider scrub during low-usage periods
4. Check for fragmentation (run trim/defrag)

**Timeout Configuration:**
```bash
# In configs/zfs-das.conf
SCRUB_TIMEOUT=2880  # 48 hours (in minutes)
```

---

### Scrub Finds Errors

**Symptoms:** "repaired" shows non-zero value

**Action:**
1. Check error details:
   ```bash
   zpool status -v media_pool
   ```

2. Identify affected files:
   ```bash
   zpool status -v media_pool | grep "permanent errors"
   ```

3. If errors persist after scrub:
   - Check drive health with SMART tools
   - Consider replacing failing drive
   - Restore from backup if data corrupted

---

### Maintenance Won't Start

**Check LaunchDaemon:**
```bash
# Is it loaded?
sudo launchctl list | grep maintenance

# Any errors?
log show --predicate 'subsystem == "com.apple.launchd"' --last 1d | grep maintenance

# Manually trigger to test
sudo /usr/local/bin/zfs-maintenance.sh
```

---

### Email Notifications Not Sent

**Verify Configuration:**
```bash
# Check config
grep EMAIL configs/zfs-das.conf

# Test mail command
echo "Test" | mail -s "Test" your@email.com

# Check logs for email errors
grep -i "email\|mail" /var/log/zfs-maintenance.log
```

---

## Advanced Configuration

### Custom Maintenance  Window

Edit timing in LaunchDaemon:

```xml
<!-- Run on Sundays at 3:00 AM -->
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>0</integer>  <!-- 0=Sunday -->
    <key>Hour</key>
    <integer>3</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

---

### Maintenance Logging

**Log Rotation:**
```bash
# Create newsyslog config
sudo tee /etc/newsyslog.d/zfs-maintenance.conf << EOF
# ZFS maintenance log rotation
/var/log/zfs-maintenance.log    644  7    *    @T00  J
EOF
```

**Log Analysis:**
```bash
# View all maintenance runs
grep "Monthly ZFS Maintenance" /var/log/zfs-maintenance.log

# Check for errors
grep "ERROR\|FATAL\|✗" /var/log/zfs-maintenance.log

# Count scrub completions
grep "Scrub completed" /var/log/zfs-maintenance.log | wc -l
```

---

## Quick Reference

### Start Manual Scrub
```bash
sudo ./scripts/trigger-scrub.sh
```

### Check Scrub Status
```bash
zpool status media_pool | grep scan
```

### Stop Running Scrub
```bash
sudo zpool scrub -s media_pool
```

### Run Full Maintenance Now
```bash
sudo /usr/local/bin/zfs-maintenance.sh
```

### View Maintenance Logs
```bash
tail -f /var/log/zfs-maintenance.log
```

### Check Next Scheduled Maintenance
```bash
sudo launchctl print system/com.local.zfs.maintenance | grep NextRunTime
```

---

## Summary

**Maintenance Components:**
- ✅ Automated monthly scrub (LaunchDaemon)
- ✅ Manual scrub trigger utility
- ✅ Pre/post maintenance hooks
- ✅ Email notifications
- ✅ Progress monitoring
- ✅ Comprehensive logging
- ✅ Error detection and reporting

**Result:** A complete, automated, and monitored maintenance system! 🎯
