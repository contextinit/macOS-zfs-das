# Complete Setup Guide

This guide walks you through setting up ZFS on macOS with Direct Attached Storage (DAS) from scratch.

## Prerequisites

Before you begin, ensure you have:

- **macOS 10.13 (High Sierra) or later**
- **OpenZFS on macOS installed** (see Installation section below)
- **Direct Attached Storage (DAS)** connected via USB, Thunderbolt, or SATA
  - Minimum 3-4 drives recommended for RAID-Z1/Z2
  - All data on these drives will be erased during setup
- **Administrator/root access** to your Mac
- **Homebrew** (optional but recommended) - [Install from brew.sh](https://brew.sh)

## Installation

### Step 1: Install OpenZFS

**Option A: Using Homebrew (Recommended)**
```bash
brew install openzfs
```

**Option B: Manual Installation**
1. Download the latest release from [OpenZFS on macOS](https://openzfsonosx.org/)
2. Open the .pkg installer and follow the prompts
3. Restart your Mac after installation

**Verify Installation:**
```bash
zpool version
zfs version
```

### Step 2: Download This Project

**Option A: Git Clone**
```bash
cd ~/Projects  # or your preferred directory
git clone https://github.com/contextinit/macos-zfs-das.git
cd macos-zfs-das
```

**Option B: Download ZIP**
1. Visit [GitHub Repository](https://github.com/contextinit/macos-zfs-das)
2. Click "Code" → "Download ZIP"
3. Extract to your preferred location

### Step 3: Run Prerequisites Check

```bash
cd macos-zfs-das
chmod +x scripts/check-prerequisites.sh
./scripts/check-prerequisites.sh
```

This script verifies:
- OpenZFS installation
- Connected drives
- System requirements
- Required commands availability

## Creating Your First ZFS Pool

### Using the Interactive Wizard (Recommended)

The easiest way to create a pool is using our web-based wizard:

1. Start the development server (if using the website locally)
2. Navigate to the Pool Creation Wizard
3. Follow the step-by-step guide

### Manual Pool Creation

If you prefer the command line:

**1. List Available Disks:**
```bash
diskutil list
```

**2. Identify Your DAS Drives** (e.g., disk2, disk3, disk4, disk5)

⚠️ **WARNING:** The next steps will ERASE all data on the selected drives!

**3. Create a RAID-Z1 Pool** (survives 1 disk failure):
```bash
sudo zpool create mypool raidz disk2 disk3 disk4 disk5
```

**4. Create a RAID-Z2 Pool** (survives 2 disk failures - recommended):
```bash
sudo zpool create mypool raidz2 disk2 disk3 disk4 disk5 disk6
```

**5. Enable Compression:**
```bash
sudo zfs set compression=lz4 mypool
```

**6. Set Mount Point:**
```bash
sudo zfs set mountpoint=/Volumes/mypool mypool
```

## Post-Setup Configuration

### Enable Auto-Mount

```bash
chmod +x scripts/zfs-automount.sh
sudo cp configs/launchd/com.local.zfs.automount.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.local.zfs.automount.plist
```

### Configure Monitoring

See [MONITORING.md](./MONITORING.md) for detailed monitoring setup with SwiftBar.

### Set Up Encryption

See [ENCRYPTION.md](./ENCRYPTION.md) for encryption configuration.

### Configure Automated Maintenance

```bash
sudo cp configs/launchd/com.local.zfs.healthcheck.plist /Library/LaunchDaemons/
sudo cp configs/launchd/com.local.zfs.maintenance.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.local.zfs.healthcheck.plist
sudo launchctl load /Library/LaunchDaemons/com.local.zfs.maintenance.plist
```

## Verification

After setup, verify your pool:

```bash
# Check pool status
zpool status

# Check pool capacity
zpool list

# Check filesystem properties
zfs get all mypool
```

Your pool should show:
- `state: ONLINE`
- All disks showing `ONLINE`
- Compression enabled (if configured)

## Next Steps

- [Configure Time Machine backups (TIME_MACHINE.md)](./TIME_MACHINE.md)
- [Set up monitoring and alerts (MONITORING.md)](./MONITORING.md)
- [Learn about maintenance tasks (MAINTENANCE.md)](./MAINTENANCE.md)
- [Troubleshooting common issues (TROUBLESHOOTING.md)](./TROUBLESHOOTING.md)

## FAQ

**Q: How much space do I lose to redundancy?**
- RAID-Z1: Lose 1 drive's worth (e.g., 5x4TB = 16TB usable)
- RAID-Z2: Lose 2 drives' worth (e.g., 6x4TB = 16TB usable)

**Q: Can I add more drives later?**
- You cannot expand an existing vdev, but you can add new vdevs to the pool.

**Q: What if a drive fails?**
- RAID-Z1/Z2 keeps your data safe. Replace the failed drive and resilver.

**Q: Should I use encryption?**
- Yes, for sensitive data. Set it up during initial creation (can't be added later to existing datasets without recreation).
