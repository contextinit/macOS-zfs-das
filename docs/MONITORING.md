# Monitoring Guide

## Overview

Comprehensive monitoring solution for ZFS pools including SwiftBar menu bar integration, proactive health checks, and alerting.

## Monitoring Components

### 1. SwiftBar Menu Bar Monitoring

Real-time visual monitoring in your macOS menu bar.

**Plugins Available:**

#### Basic Monitor ([zfs-monitor.30s.sh](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/swiftbar/zfs-monitor.30s.sh))

**Features:**
- Pool health status
- Capacity percentage
- Error count
- Time Machine status
- Quick actions menu

**Display:**
```
🟢 ZFS 45%  ← Menu bar
```

#### Advanced Monitor ([zfs-advanced.30s.sh](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/swiftbar/zfs-advanced.30s.sh))

**Features:**
- All basic features PLUS:
- Trending graphs
- ARC statistics
- Per-dataset details
- Historical data
- Alert thresholds
- Fragmentation monitoring

**Display:**
```
🟢 ZFS 45% ↗  ← Menu bar (with trend)
```

**Setup:** See [docs/SETUP.md](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/docs/SETUP.md) or use `setup-monitoring.sh`

---

### 2. Automated Health Checks

Proactive monitoring that alerts you to issues before they become critical.

**Script:** [scripts/health-check.sh](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/scripts/health-check.sh)

**What It Monitors:**

| Check | Threshold | Alert Level |
|-------|-----------|-------------|
| Pool Health | Not ONLINE | CRITICAL |
| Capacity | 70% | WARNING |
| Capacity | 85% | CRITICAL |
| Read Errors | > 0 | CRITICAL |
| Write Errors | > 0 | CRITICAL |
| Scrub Age | > 35 days | WARNING |
| Encryption Keys | Unavailable | WARNING |
| Unmounted Datasets | > 0 | WARNING |
| Auto-Mount Service | Not running | WARNING |

**Schedule:** Every 6 hours (00:00, 06:00, 12:00, 18:00)

**Installation:**
```bash
# Copy health check script
sudo cp scripts/health-check.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/health-check.sh

# Install LaunchDaemon
sudo cp configs/launchd/com.local.zfs.healthcheck.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.local.zfs.healthcheck.plist
```

**Manual Run:**
```bash
sudo /usr/local/bin/health-check.sh
```

---

### 3. Status Check Utility

On-demand comprehensive status check.

**Script:** [scripts/check-zfs-status.sh](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/scripts/check-zfs-status.sh)

**Usage:**
```bash
# Quick status check
./scripts/check-zfs-status.sh

# Check specific pool
./scripts/check-zfs-status.sh backup_pool

# Use in monitoring scripts
if ./scripts/check-zfs-status.sh; then
    echo "All healthy"
else
    echo "Issues detected"
fi
```

**See:** [docs/USER_EXPERIENCE.md](file:///Users/ram/Documents/Projects/Public/macos-zfs-das/docs/USER_EXPERIENCE.md) for full documentation

---

## Alert Channels

### macOS Notifications

**Configuration:**
```bash
# In configs/zfs-das.conf
ENABLE_NOTIFICATIONS=true
NOTIFICATION_SOUND="Basso"
```

**Notification Types:**
- 🔴 **CRITICAL** - Immediate attention required
- 🟡 **WARNING** - Should investigate soon
- 🔵 **INFO** - Informational only

**Example:**
```
Title: "Pool Health Critical"
Message: "Pool 'media_pool' health is DEGRADED (not ONLINE).
         Immediate attention required!"
Sound: Basso
```

---

### Email Alerts

**Configuration:**
```bash
# In configs/zfs-das.conf
ENABLE_EMAIL=true
EMAIL_ADDRESS="admin@example.com"
EMAIL_SUBJECT_PREFIX="[ZFS-ALERT]"
```

**Prerequisites:**
```bash
# macOS mail command must be configured
# Test with:
echo "Test" | mail -s "Test" your@email.com
```

**Email Format:**
```
Subject: [ZFS-ALERT] Pool Capacity Critical
From: root@your-mac.local
To: admin@example.com

Pool 'media_pool' is 87% full (critical threshold: 85%).
Running out of space!

---
Sent by ZFS DAS Health Monitor
Time: 2024-12-13 18:00:00
```

---

### Log Files

**Location:** `/var/log/`

| Log File | Purpose | Rotation |
|----------|---------|----------|
| `zfs-automount.log` | Boot-time mounting | Daily |
| `zfs-maintenance.log` | Monthly maintenance | Monthly |
| `zfs-health-check.log` | Health checks | Daily |

**Monitoring Logs:**
```bash
# Watch health check log
tail -f /var/log/zfs-health-check.log

# Show recent alerts
grep "CRITICAL\|WARNING" /var/log/zfs-health-check.log | tail -20

# Count alerts today
grep "$(date +%Y-%m-%d)" /var/log/zfs-health-check.log | grep -c "CRITICAL\|WARNING"
```

---

## Monitoring Best Practices

### 1. Choose Your Monitoring Level

**Minimal (Default):**
- SwiftBar basic monitor
- Built-in health checks (6-hour interval)
- macOS notifications only

**Standard (Recommended):**
- SwiftBar advanced monitor
- Health checks with email alerts
- Regular log review

**Enterprise:**
- SwiftBar advanced monitor
- Health checks with email
- Integration with monitoring platform (Prometheus/Grafana)
- Custom alerting rules

---

### 2. Configure Alert Thresholds

Adjust thresholds based on your usage:

**Conservative (safer, more alerts):**
```bash
CAPACITY_WARNING=60
CAPACITY_CRITICAL=75
ERROR_THRESHOLD=0  # Alert on any error
SCRUB_MAX_AGE_DAYS=30
```

**Standard (balanced):**
```bash
CAPACITY_WARNING=70
CAPACITY_CRITICAL=85
ERROR_THRESHOLD=1
SCRUB_MAX_AGE_DAYS=35
```

**Relaxed (fewer alerts):**
```bash
CAPACITY_WARNING=80
CAPACITY_CRITICAL=90
ERROR_THRESHOLD=5
SCRUB_MAX_AGE_DAYS=45
```

---

### 3. Review Schedule

Establish a regular review schedule:

**Daily:**
- Glance at SwiftBar menu bar
- Check for notifications

**Weekly:**
- Review capacity trends
- Check scrub status
- Verify backups

**Monthly:**
- Review all logs
- Validate encryption keys
- Test recovery procedures
- Review alert thresholds

**Quarterly:**
- Run security audit
- Update documentation
- Test disaster recovery

---

## Troubleshooting Monitoring

### SwiftBar Not Updating

1. Check SwiftBar is running
2. Verify plugin permissions (must be executable)
3. Check plugin syntax:
   ```bash
   bash -n swiftbar/zfs-monitor.30s.sh
   ```
4. View plugin output manually:
   ```bash
   ./swiftbar/zfs-monitor.30s.sh
   ```

### No Health Check Alerts

1. Check LaunchDaemon is loaded:
   ```bash
   sudo launchctl list | grep healthcheck
   ```

2. View recent health check logs:
   ```bash
   tail -50 /var/log/zfs-health-check.log
   ```

3. Test manually:
   ```bash
   sudo /usr/local/bin/health-check.sh
   ```

4. Verify notification settings:
   ```bash
   grep ENABLE_NOTIFICATIONS configs/zfs-das.conf
   ```

### Email Alerts Not Working

1. Test mail command:
   ```bash
   echo "Test" | mail -s "Test Subject" your@email.com
   ```

2. Configure macOS mail (if needed):
   ```bash
   # May need to configure SMTP settings
   # See: System Preferences → Internet Accounts
   ```

3. Check email address in config:
   ```bash
   grep EMAIL_ADDRESS configs/zfs-das.conf
   ```

---

## Advanced Monitoring

### Integration with Prometheus

Export metrics for Grafana dashboards:

**Script:** (Future enhancement)
```bash
#!/bin/bash
# zfs-exporter.sh
# Exports ZFS metrics in Prometheus format

echo "# HELP zfs_pool_health Pool health status"
echo "# TYPE zfs_pool_health gauge"
echo "zfs_pool_health{pool=\"media_pool\"} 1"  # 1=ONLINE, 0=not ONLINE

echo "# HELP zfs_pool_capacity_percent Pool capacity percentage"
echo "# TYPE zfs_pool_capacity_percent gauge"
CAPACITY=$(zpool list -H -o capacity media_pool | tr -d '%')
echo "zfs_pool_capacity_percent{pool=\"media_pool\"} $CAPACITY"
```

### Custom Alert Scripts

Create custom alert conditions:

```bash
#!/bin/bash
# custom-alert.sh
# Alert if pool is > 80% AND has errors

CAPACITY=$(zpool list -H -o capacity media_pool | tr -d '%')
ERRORS=$(zpool status media_pool | grep -c "errors:")

if [ "$CAPACITY" -gt 80 ] && [ "$ERRORS" -gt 0 ]; then
    osascript -e 'display notification "Pool is full AND has errors!" with title "CRITICAL"'
fi
```

### Slack/Discord Integration

Send alerts to team channels:

```bash
# In health-check.sh, add webhook:
send_slack_alert() {
    local message="$1"
    local webhook_url="YOUR_WEBHOOK_URL"
    
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        "$webhook_url"
}
```

---

## Monitoring Dashboard

### SwiftBar Menu Display

**Color Coding:**
- 🟢 **Green** - All healthy (capacity < 70%)
- 🟡 **Yellow** - Warning (capacity 70-85%)
- 🔴 **Red** - Critical (capacity > 85% or errors)

**Icons:**
- ✓ - Healthy/normal
- ⚠ - Warning
- ✗ - Critical
- ⟳ - In progress (scrub)
- 🔒 - Encrypted

**Example Display:**
```
Menu Bar:
🟢 ZFS 45% ↗

Dropdown:
═══════════════════════════
Pool: media_pool
Health: ✓ ONLINE
Capacity: 45% (4.5T / 10T)
Last Scrub: 5 days ago ✓
Errors: None ✓
───────────────────────────
Datasets:
  data       🔒 4.5T
  backups    🔒 2.1T
  photos     🔒 1.2T
───────────────────────────
Time Machine: ✓ Active
───────────────────────────
Actions:
  • Check Status
  • Run Scrub
  • View Logs
  • Security Audit
═══════════════════════════
```

---

## Quick Reference

### Monitor Setup
```bash
# Install SwiftBar monitoring
./scripts/setup-monitoring.sh

# Install health checks
sudo cp scripts/health-check.sh /usr/local/bin/
sudo cp configs/launchd/com.local.zfs.healthcheck.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.local.zfs.healthcheck.plist
```

### Check Status
```bash
# Menu bar - Glance at SwiftBar
# Quick check
./scripts/check-zfs-status.sh

# Detailed
sudo zpool status -v media_pool
```

### View Alerts
```bash
# Recent health check alerts
grep "CRITICAL\|WARNING" /var/log/zfs-health-check.log | tail -20

# Check notification history
# System Preferences → Notifications → Check history
```

### Test Monitoring
```bash
# Test health check
sudo /usr/local/bin/health-check.sh

# Test status check
./scripts/check-zfs-status.sh

# Test SwiftBar plugin
./swiftbar/zfs-monitor.30s.sh
```

---

## Summary

**Monitoring Components:**
- ✅ SwiftBar menu bar (real-time visual)
- ✅ Automated health checks (proactive)
- ✅ Status utility (on-demand)
- ✅ macOS notifications (immediate)
- ✅ Email alerts (remote)
- ✅ Comprehensive logging (historical)

**Alert Coverage:**
- ✅ Pool health
- ✅ Capacity warnings
- ✅ Error detection
- ✅ Scrub monitoring
- ✅ Encryption status
- ✅ Mount validation
- ✅ Service status

**Result:** Complete monitoring coverage with multiple alert channels! 🎯
