# Time Machine Setup

Configure your ZFS pool as a network Time Machine destination for backing up macOS computers.

## Overview

ZFS makes an excellent Time Machine destination with benefits including:
- Data integrity verification
- Snapshots for backup history
- Compression to save space
- Multiple Mac support with quotas

## Prerequisites

- Existing ZFS pool (see [SETUP.md](./SETUP.md))
- macOS with network access to the ZFS server
- AFP or SMB for file sharing

## Quick Setup with the Main Wizard

The easiest way is through the interactive setup wizard. During **Phase 6**, the wizard asks for:
- Time Machine computer name (used as the dataset name)
- Quota size (e.g. `500G`)

The wizard then creates the dataset, sets properties, and configures sharing automatically.

```bash
bash scripts/setup.sh
```

Alternatively, use the web-based command generator at `/wizards/timemachine` on the project website — it produces the exact commands to paste into Terminal.

## Manual Configuration

### Step 1: Create Time Machine Dataset

```bash
# Create a dedicated dataset for Time Machine
sudo zfs create mypool/timemachine

# Set mount point
sudo zfs set mountpoint=/Volumes/mypool/timemachine mypool/timemachine

# Enable compression (saves significant space)
sudo zfs set compression=lz4 mypool/timemachine

# Set quota (optional, recommended per-Mac)
sudo zfs set quota=500G mypool/timemachine
```

### Step 2: Create Per-Mac Datasets (Recommended)

For multiple Macs, create individual datasets with quotas:

```bash
# For Mac #1
sudo zfs create mypool/timemachine/macbook-pro
sudo zfs set quota=300G mypool/timemachine/macbook-pro

# For Mac #2
sudo zfs create mypool/timemachine/imac
sudo zfs set quota=500G mypool/timemachine/imac
```

### Step 3: Configure Sharing

**Option A: SMB (recommended — built into macOS)**

Enable file sharing in **System Settings → General → Sharing → File Sharing**, then add the Time Machine mount point as a shared folder. In the share's Advanced Options, enable "Share as a Time Machine backup destination".

**Option B: AFP via netatalk** (third-party, for older macOS clients)

Install netatalk:
```bash
brew install netatalk
```

**Configure /usr/local/etc/afp.conf:**
```ini
[Global]
  mimic model = TimeCapsule8,119

[Time Machine]
  path = /Volumes/mypool/timemachine
  time machine = yes
  vol size limit = 500000
```

**Start AFP service:**
```bash
sudo brew services start netatalk
```

### Step 4 (Alternative): Configure SMB Sharing

**Edit /etc/smb.conf** (or create if doesn't exist):
```ini
[Time Machine]
  path = /Volumes/mypool/timemachine
  valid users = yourusername
  read only = no
  vfs objects = catia fruit streams_xattr
  fruit:time machine = yes
```

**Start SMB:**
```bash
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
```

### Step 5: Configure on Client Mac

**Using AFP:**
1. Open **System Preferences** → **Time Machine**
2. Click **Select Disk**
3. Choose your server (should appear as `<hostname>.local`)
4. Select the Time Machine share
5. Enter credentials if prompted
6. Click **Use Disk**

**Using SMB:**
1. In Finder, Go → Connect to Server (`⌘K`)
2. Enter: `smb://<your-server-ip>/Time Machine`
3. Mount the share
4. Open Time Machine preferences and select the mounted volume

## Using the Setup Script

We provide a helper script for automated configuration:

```bash
cd macos-zfs-das

# Make executable
chmod +x scripts/setup-timemachine.sh

# Run with pool and dataset name
sudo ./scripts/setup-timemachine.sh mypool timemachine

# The script will:
# - Create the Time Machine dataset
# - Set recommended properties
# - Configure sharing (you'll be prompted)
# - Guide you through client setup
```

## Maintenance

### Check Space Usage

```bash
# Overall dataset
zfs list mypool/timemachine

# Per-Mac datasets
zfs list -r mypool/timemachine

# With human-readable sizes
zfs list -r -o name,used,available,quota mypool/timemachine
```

### Adjust Quotas

```bash
# Increase quota for a specific Mac
sudo zfs set quota=800G mypool/timemachine/macbook-pro

# Remove quota (unlimited)
sudo zfs set quota=none mypool/timemachine/macbook-pro
```

### Create Snapshots

Take periodic snapshots of Time Machine data for extra protection:

```bash
# Manual snapshot
sudo zfs snapshot mypool/timemachine@weekly-$(date +%Y%m%d)

# Automated snapshots (add to cron or launchd)
sudo zfs snapshot -r mypool/timemachine@daily-$(date +%Y%m%d)
```

### Delete Old Backups

If you need to free up space:

```bash
# Enter Time Machine and thin out old backups
tmutil thinlocalsnapshots / 100000000000 4  # Keep last 4 weeks
```

## Troubleshooting

### Time Machine Doesn't See the Volume

1. **Check sharing service:**
   ```bash
   # AFP
   brew services list | grep netatalk
   
   # SMB
   sudo launchctl list | grep smb
   ```

2. **Verify network connectivity:**
   ```bash
   ping <server-ip>
   ```

3. **Check firewall settings** on server Mac

### Slow Initial Backup

- Initial backups are always slow (could take 12-24 hours for 500GB)
- Ensure both Macs are using Gigabit Ethernet or faster
- Use SMB3 for better performance than AFP

### "Disk Full" Errors

```bash
# Check actual usage
zfs list mypool/timemachine

# Check quotas
zfs get quota mypool/timemachine

# Increase quota if needed
sudo zfs set quota=1T mypool/timemachine
```

## Best Practices

1. **Set quotas per Mac** to prevent one Mac from consuming all space
2. **Use compression** (LZ4 is fast and saves 20-30%)
3. **Take ZFS snapshots** of your Time Machine dataset weekly
4. **Monitor space usage** regularly
5. **Use Ethernet** for faster backups (WiFi is slow for large backups)
6. **Exclude large files** from Time Machine (cache, logs, VMs) to save space

## Advanced: Multiple Network Clients

For advanced users managing backups from multiple Macs:

```bash
# Create structure
sudo zfs create mypool/timemachine
sudo zfs set compression=lz4 mypool/timemachine
sudo zfs set mountpoint=/Volumes/timemachine mypool/timemachine

# Per-user datasets with quotas
for mac in macbook-pro imac mac-mini; do
  sudo zfs create mypool/timemachine/$mac
  sudo zfs set quota=500G mypool/timemachine/$mac
done

# Share each with AFP
# Configure afp.conf with multiple sections
```

## See Also

- [SETUP.md](./SETUP.md) - Initial ZFS pool setup
- [MONITORING.md](./MONITORING.md) - Monitor your Time Machine backups
- [MAINTENANCE.md](./MAINTENANCE.md) - Regular maintenance tasks
