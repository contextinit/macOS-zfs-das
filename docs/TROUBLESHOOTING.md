# Troubleshooting

Common issues and solutions when working with ZFS on macOS.

## Installation Issues

### OpenZFS Won't Install

**Error: "System Extension Blocked"**

**Solution:**
1. Open **System Preferences** → **Security & Privacy**
2. Click the lock to make changes
3. Click **Allow** next to the OpenZFS system extension
4. Restart your Mac

**Error: "Operation not permitted" during installation**

**Solution:**
```bash
# Disable SIP temporarily (only if necessary)
# 1. Restart in Recovery Mode (⌘R during boot)
# 2. Open Terminal and run:
csrutil disable
# 3. Restart normally
# 4. Install OpenZFS
# 5. Re-enable SIP (repeat step 1-2, then):
csrutil enable
```

### Homebrew Installation Fails

**Solution:**
```bash
# Update Homebrew
brew update

# Try installing again
brew install openzfs

# If still fails, install from GitHub release
# Visit https://openzfsonosx.org/
```

## Pool Creation Issues

### "Cannot Create Pool: Permission Denied"

**Solution:**
```bash
# Always use sudo for zpool commands
sudo zpool create mypool raidz disk2 disk3 disk4
```

### "Device is Busy"

The disk might be mounted by macOS.

**Solution:**
```bash
# Unmount the disk first
diskutil unmountDisk disk2

# Then create pool
sudo zpool create mypool raidz disk2 disk3 disk4
```

### "Invalid vdev specification"

Wrong disk identifiers.

**Solution:**
```bash
# List all disks
diskutil list

# Use the correct disk identifiers (diskX, not diskXsY)
# ✅ Correct: disk2 disk3 disk4
# ❌ Wrong: disk2s1 disk3s1 disk4s1
```

### "No Such Pool" After Creating

Pool didn't import automatically.

**Solution:**
```bash
# Import the pool manually
sudo zpool import

# Import specific pool
sudo zpool import mypool
```

## Pool Import/Export Issues

### Pool Won't Import After Restart

**Solution:**
```bash
# Check if pool is available
sudo zpool import

# Import with force flag if shown as in use
sudo zpool import -f mypool

# Check pool status
sudo zpool status mypool
```

### "Pool is Currently Imported on Another System"

**Solution:**
```bash
# Force import (only if you're sure it's safe)
sudo zpool import -f mypool
```

## Performance Issues

### Slow Read/Write Speeds

**Check pool status:**
```bash
sudo zpool iostat -v 2
```

**Possible causes and solutions:**

1. **USB connection** - Use Thunderbolt or eSATA for better speed
2. **Fragmentation** - Defrag might help:
   ```bash
   # There's no built-in defrag, but you can copy and replace
   ```
3. **Too many snapshots** - Delete old snapshots:
   ```bash
   zfs list -t snapshot
   sudo zfs destroy mypool@old-snapshot
   ```

### High CPU Usage

**Solution:**
```bash
# Disable compression if CPU-bound
sudo zfs set compression=off mypool

# Or use lighter compression
sudo zfs set compression=lz4 mypool  # Fast and efficient
```

## Data Integrity Issues

### Checksum Errors

**Check for errors:**
```bash
sudo zpool status -v
```

**If errors found:**
```bash
# Run scrub to repair
sudo zpool scrub mypool

# Check progress
sudo zpool status mypool

# After scrub completes, clear errors
sudo zpool clear mypool
```

### Disk Failure

**Identify failed disk:**
```bash
sudo zpool status mypool
```

Look for `DEGRADED`, `FAULTED`, or `UNAVAIL` status.

**Replace failed disk:**
```bash
# 1. Physically replace the drive
# 2. Get the device id
diskutil list

# 3. Replace in pool
sudo zpool replace mypool <old-disk> <new-disk>

# 4. Wait for resilver to complete
sudo zpool status mypool
```

## Mounting Issues

### Pool Won't Mount

**Solution:**
```bash
# Check if pool is imported
zpool list

# If not, import it
sudo zpool import mypool

# Set mount point if needed
sudo zfs set mountpoint=/Volumes/mypool mypool

# Force mount
sudo zfs mount mypool
```

### "Cannot Mount: Permission Denied"

**Solution:**
```bash
# Run as sudo
sudo zfs mount mypool

# Check permissions
ls -la /Volumes/
```

### Dataset Not Appearing in Finder

**Solution:**
```bash
# Check if mounted
zfs get mounted mypool

# Mount if needed
sudo zfs mount mypool

# Set correct permissions
sudo chmod 755 /Volumes/mypool
sudo chown $(whoami):staff /Volumes/mypool
```

## Encryption Issues

### "Cannot Load Key: Incorrect Key Provided"

**Solution:**
```bash
# Reload key with correct path
sudo zfs load-key -L file:///path/to/correct/key mypool/encrypted

# Or enter key manually
sudo zfs load-key mypool/encrypted
```

### "Cannot Mount: Encryption Key Not Loaded"

**Solution:**
```bash
# Load key first
sudo zfs load-key mypool/encrypted

# Then mount
sudo zfs mount mypool/encrypted
```

## Space Issues

### "No Space Left on Device" But Pool Shows Free Space

**Check quotas:**
```bash
zfs get quota,used,available mypool

# Remove or increase quota
sudo zfs set quota=none mypool
```

**Check reservations:**
```bash
zfs get reservation mypool

# Remove reservation
sudo zfs set reservation=none mypool
```

### Pool Filling Up Unexpectedly

**Find what's using space:**
```bash
# List datasets by size
zfs list -o name,used,available -S used

# Check snapshots
zfs list -t snapshot -o name,used -S used

# Delete old snapshots
sudo zfs destroy mypool@old-snapshot
```

## Snapshot Issues

### Cannot Delete Snapshot

**Error: "Dataset is busy"**

**Solution:**
```bash
# Unmount the dataset
sudo zfs unmount mypool/dataset

# Delete snapshot
sudo zfs destroy mypool/dataset@snapshot

# Remount
sudo zfs mount mypool/dataset
```

### Snapshots Taking Too Much Space

**Solution:**
```bash
# List snapshots by size
zfs list -t snapshot -o name,used -S used

# Delete oldest snapshots
sudo zfs destroy mypool@snapshot-name

# Delete range of snapshots
sudo zfs destroy mypool@2023-01-01%2023-12-31
```

## Time Machine Issues

### Time Machine Can't See the Volume

**Solution:**
1. Check sharing is enabled (AFP or SMB)
2. Verify network connectivity
3. Check firewall settings
4. Ensure Time Machine dataset is mounted

```bash
# Check if dataset is mounted
zfs get mounted mypool/timemachine

# Check AFP service
brew services list | grep netatalk

# Check SMB service
sudo launchctl list | grep smb
```

### Time Machine Backup Slow

**Solutions:**
- Use Gigabit Ethernet (WiFi is very slow)
- Enable compression on Time Machine dataset
  ```bash
  sudo zfs set compression=lz4 mypool/timemachine
  ```
- Exclude large unnecessary files in Time Machine preferences

## Monitoring/Script Issues

### SwiftBar Plugin Not Showing

**Solution:**
```bash
# Check plugin path
ls -la ~/Library/Application\ Support/SwiftBar/

# Make plugin executable
chmod +x ~/Library/Application\ Support/SwiftBar/zfs-monitor.30s.sh

# Check SwiftBar is running
ps aux | grep SwiftBar
```

### Automated Scripts Not Running

**Solution:**
```bash
# Check launchd agents are loaded
launchctl list | grep zfs

# Reload if needed
launchctl unload ~/Library/LaunchAgents/com.local.zfs.healthcheck.plist
launchctl load ~/Library/LaunchAgents/com.local.zfs.healthcheck.plist

# Check script permissions
chmod +x scripts/*.sh
```

## Kernel Extension Issues

### "Kernel Extension Not Loaded"

**Solution:**
```bash
# Check if loaded
kextstat | grep zfs

# Load manually
sudo kextload /Library/Extensions/zfs.kext

# If fails, check system extension security
```

## Getting More Help

### Enable Debug Logging

```bash
# Set ZFS debug level
sudo sysctl -w vfs.zfs.debuglevel=1

# Check system log
log show --predicate 'process == "zfs"' --last 1h
```

### Collect Diagnostic Information

```bash
# Run diagnostics script
chmod +x scripts/diagnostics.sh
sudo ./scripts/diagnostics.sh > zfs-diagnostics.txt

# This creates a report with:
# - Pool status
# - System info
# - Recent errors
# - Configuration
```

### Report Issues

If you can't resolve the issue:

1. **Check existing issues**: [GitHub Issues](https://github.com/contextinit/macos-zfs-das/issues)
2. **Run diagnostics** (above) and attach output
3. **Create new issue** with:
   - What you were trying to do
   - What happened instead
   - Steps to reproduce
   - Diagnostic output
   - macOS version
   - OpenZFS version

## See Also

- [SETUP.md](./SETUP.md) - Setup guide
- [MAINTENANCE.md](./MAINTENANCE.md) - Maintenance procedures
- [OpenZFS Documentation](https://openzfs.github.io/openzfs-docs/)
