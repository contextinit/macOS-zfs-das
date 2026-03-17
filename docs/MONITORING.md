# Monitoring Guide

SwiftBar menu bar integration, health checks, and alerting for ZFS pools on macOS.

## Overview

Two SwiftBar plugins are included. Both auto-refresh every 30 seconds and display pool health in your menu bar:

| Plugin | File | Best for |
|---|---|---|
| Standard | `swiftbar/zfs-monitor.30s.sh` | Most users — clean, essential stats |
| Advanced | `swiftbar/zfs-advanced.30s.sh` | Power users — ARC stats, trends, snapshot actions |

## Installation

### Via Setup Wizard (Recommended)

During Phase 6 of `bash scripts/setup.sh`, choose a plugin level. The wizard installs SwiftBar and copies the plugin automatically.

### Manual Installation

```bash
# Install SwiftBar (fetches latest version from GitHub — no Homebrew needed)
bash scripts/install-swiftbar.sh

# Or install with a custom plugin directory
bash scripts/install-swiftbar.sh --plugin-dir ~/my-plugins
```

`install-swiftbar.sh` automatically:
- Fetches the latest SwiftBar release via GitHub Releases API
- Skips download if SwiftBar is already up to date
- Removes macOS Gatekeeper quarantine (`xattr -dr com.apple.quarantine`)
- Copies all `swiftbar/*.sh` plugins to your plugin directory
- Launches SwiftBar if it is not already running

### Manual Plugin Copy

```bash
PLUGIN_DIR=~/Library/Application\ Support/SwiftBar/Plugins

# Standard plugin
cp swiftbar/zfs-monitor.30s.sh "$PLUGIN_DIR/"
chmod +x "$PLUGIN_DIR/zfs-monitor.30s.sh"

# Advanced plugin (choose one)
cp swiftbar/zfs-advanced.30s.sh "$PLUGIN_DIR/"
chmod +x "$PLUGIN_DIR/zfs-advanced.30s.sh"
```

Then open SwiftBar and set the plugin directory.

## Plugin Features

### Standard Plugin (`zfs-monitor.30s.sh`)

**Menu bar**: Pool name + health status icon

**Menu items:**
- Pool health (ONLINE / DEGRADED / FAULTED)
- Capacity percentage with colour warning (yellow > 70%, red > 85%)
- Used / available storage
- Dataset list with mount status
- Error count (read, write, checksum)
- Last scrub date and result
- Quick actions: Refresh, Open Console, Run Scrub

### Advanced Plugin (`zfs-advanced.30s.sh`)

Everything in the standard plugin, plus:

- **Visual capacity bar**: Unicode block bar (e.g. `████████░░░░ 67%`)
- **ARC statistics**: Hit rate, cache size, evictions (via `sysctl` — no external dependencies)
- **Trend arrows**: Capacity trend over time (↑ filling / ↓ freeing / → stable), calculated from a file-locked cache to prevent race conditions
- **Compression ratio**: Per-dataset compression savings
- **Encryption status**: Per-dataset encryption indicator
- **Snapshot management**: Create snapshot, list recent snapshots, delete snapshot — all from the menu bar
- **I/O statistics**: Read/write ops per second via `zpool iostat`

### SF Symbols & Dark/Light Mode (SwiftBar v2)

Both plugins detect the macOS appearance (`$OS_APPEARANCE`) and adapt colours accordingly. When running under SwiftBar v2, menu items use SF Symbols for a native look:

| Status | Icon |
|---|---|
| ONLINE | `checkmark.circle.fill` (green) |
| DEGRADED | `exclamationmark.triangle.fill` (yellow) |
| FAULTED | `xmark.circle.fill` (red) |
| Encrypted | `lock.fill` |
| Scrub active | `arrow.clockwise.circle` |

## Configuration

Plugins read settings from `/usr/local/etc/zfs-das.conf` (created by `setup.sh`) or from defaults at the top of each plugin file.

Key variables:

```bash
POOL_NAME="mypool"           # ZFS pool to monitor
ZFS_CMD="/usr/local/zfs/bin" # OpenZFS binary path
ENCRYPTION_ENABLED=true      # Show encryption indicators
```

Override temporarily by setting env vars before opening SwiftBar, or edit the plugin file directly.

## Health Checks and Alerting

### Automated Health Checks

`scripts/health-check.sh` runs on a schedule (set up by `setup.sh`):

```bash
# Run manually
sudo bash scripts/health-check.sh mypool

# Check logs
tail -f /var/log/zfs-healthcheck.log
```

Checks performed:
- Pool health status (ONLINE / DEGRADED / FAULTED)
- Available capacity (warns at 70%, critical at 85%)
- Error counts (read, write, checksum)
- Scrub age (warns if no scrub in 30 days)
- Encryption key status

### macOS Notifications

Scripts send native macOS notifications via `osascript`:

| Event | Notification level |
|---|---|
| Pool import failed | Critical (always sent) |
| Encryption key error | Critical (always sent) |
| Pool degraded | Warning (always sent) |
| Capacity > 85% | Warning (always sent) |
| Scrub complete | Success (optional) |

Configure in `/usr/local/etc/zfs-das.conf`:
```bash
ENABLE_NOTIFICATIONS=true
NOTIFY_ON_SUCCESS=false   # Set true to see success notifications
```

## Real-Time Log Monitoring

```bash
# Auto-mount events
tail -f /var/log/zfs-automount.log

# Health check events
tail -f /var/log/zfs-healthcheck.log

# Errors only
tail -f /var/log/zfs-automount.log | grep "ERROR\|FATAL\|✗"
```

## Troubleshooting SwiftBar

**Plugin not visible in menu bar:**
```bash
# Verify plugin is executable
ls -la ~/Library/Application\ Support/SwiftBar/Plugins/

chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/zfs-monitor.30s.sh

# Verify SwiftBar is running
ps aux | grep SwiftBar
open /Applications/SwiftBar.app
```

**Plugin shows error / no data:**
```bash
# Run plugin directly in terminal to see output
bash ~/Library/Application\ Support/SwiftBar/Plugins/zfs-monitor.30s.sh

# Verify ZFS is installed and accessible
/usr/local/zfs/bin/zpool list
```

**Re-install SwiftBar:**
```bash
bash scripts/install-swiftbar.sh
```

## See Also

- [SETUP.md](./SETUP.md) — Initial pool setup
- [MAINTENANCE.md](./MAINTENANCE.md) — Scrub scheduling and maintenance
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) — Common issues
