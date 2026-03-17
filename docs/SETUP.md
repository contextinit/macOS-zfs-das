# Setup Guide

Complete guide for setting up ZFS DAS on macOS using the interactive setup wizard.

## Overview

macOS ZFS DAS turns a Direct Attached Storage (DAS) enclosure into a high-integrity ZFS pool with RAID, AES-256-GCM encryption, automatic mounting, Time Machine support, and SwiftBar menu bar monitoring — all configured through a guided terminal wizard.

## Prerequisites

| Requirement | Notes |
|---|---|
| macOS 10.13+ | Tested on Ventura, Sonoma, Sequoia |
| OpenZFS for macOS | Download `.pkg` from [openzfsonosx.org](https://openzfsonosx.org/) |
| DAS enclosure + drives | At least 2 drives for RAID redundancy |
| bash 3.2+, curl, unzip | All included with macOS |

**Install OpenZFS** (required before running setup):
1. Download the `.pkg` installer from [openzfsonosx.org](https://openzfsonosx.org/)
2. Run the installer
3. Approve the system extension in **System Settings → Privacy & Security**
4. Restart your Mac

Verify:
```bash
/usr/local/zfs/bin/zpool --version
```

## Quick Start

```bash
git clone https://github.com/contextinit/macos-zfs-das.git
cd macos-zfs-das
bash scripts/setup.sh
```

The wizard guides you through all 9 phases interactively.

## The 9-Phase Setup Wizard

| Phase | What happens |
|---|---|
| 1 — Legal | Disclaimer shown; must type `I AGREE` to proceed |
| 2 — System checks | Verifies OpenZFS, macOS version, curl, unzip, external disks |
| 3 — Drive selection | Live `diskutil list`; validates drive format, shows model/size/protocol per drive |
| 4 — Disk prep commands | Generates `diskutil eraseDisk` commands as **text only** — you run them manually |
| 5 — Pool configuration | Pool name, RAID type, compression (lz4/zstd), AES-256-GCM encryption |
| 6 — Services | Auto-mount LaunchDaemon, Time Machine (computer name + quota), SwiftBar level |
| 7 — Review & confirm | Shows full `zpool create` command preview; must type `CREATE THE POOL` to continue |
| 8 — Execution | Key generation, pool creation, datasets, config file, LaunchDaemon, SwiftBar install |
| 9 — Done | Summary and next steps |

> **Disk prep safety**: Phase 4 displays partition commands in a clearly labelled box. The wizard does **not** execute them. You copy them into a separate Terminal window after manually verifying each disk identifier. The software provider accepts no liability for data loss from incorrect drive selection.

## RAID Options

| Level | Min drives | Survives | Best for |
|---|---|---|---|
| `mirror` | 2 | 1 drive | 2-drive enclosures |
| `raidz1` | 3 | 1 drive | 3–5 drives |
| `raidz2` | 4 | 2 drives | 4–8 drives (recommended) |
| `raidz3` | 5 | 3 drives | 6+ drives, maximum redundancy |

The wizard checks drive count compatibility in real time before allowing you to proceed.

## Encryption

When you enable encryption in Phase 5:

- Algorithm: AES-256-GCM (OpenZFS native)
- A random key is generated with `openssl rand` and saved to `/etc/zfs/keys/<pool>.key` with `0400` permissions
- A SHA-256 fingerprint is shown — **record the key file path before typing the confirmation**
- The auto-mount LaunchDaemon loads the key automatically at boot

Load the key manually if needed:
```bash
sudo zfs load-key -L file:///etc/zfs/keys/<pool>.key <pool>
sudo zfs mount -a
```

## Configuration File

After setup, pool configuration is saved at `/usr/local/etc/zfs-das.conf`:

```bash
cat /usr/local/etc/zfs-das.conf
```

This file is read by the auto-mount script and SwiftBar plugins.

## Safe Testing Without Real Drives

Test the full setup using virtual disks backed by sparse images — no physical drives needed:

```bash
# Create test directory
mkdir -p /tmp/zfs-test

# Create 4 virtual 2GB disks
for i in 1 2 3 4; do
  hdiutil create -size 2g -type SPARSE -layout NONE /tmp/zfs-test/disk${i}.img
  hdiutil attach -nomount /tmp/zfs-test/disk${i}.img
done

# Note the /dev/diskN entries that appear (one per image)
diskutil list | tail -20
```

Select those disk identifiers during Phase 3 of `setup.sh`. The pool will behave identically to a real DAS pool.

**Cleanup after testing:**
```bash
sudo zpool destroy testpool 2>/dev/null
for d in $(hdiutil info | grep /tmp/zfs-test -A5 | grep '/dev/disk' | awk '{print $1}'); do
  hdiutil detach "$d" 2>/dev/null
done
rm -rf /tmp/zfs-test
```

## Manual Pool Creation (Reference)

If you prefer not to use the wizard:

```bash
# 1. Identify drives
diskutil list

# 2. Erase drives — run manually, verify identifiers first
diskutil unmountDisk /dev/disk2
diskutil eraseDisk free UNTITLED GPT /dev/disk2
# Repeat for disk3, disk4, disk5...

# 3. Create pool (using Bash array for safe expansion)
DISKS=(disk2 disk3 disk4 disk5)
sudo /usr/local/zfs/bin/zpool create \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  mypool raidz2 "${DISKS[@]}"

# 4. Create datasets
sudo zfs create mypool/data
sudo zfs create mypool/timemachine
```

## Verify Setup

```bash
bash scripts/check-prerequisites.sh   # System readiness check
sudo zpool status                      # Pool health
zfs list                               # Datasets
```

## What Gets Installed

| Component | Location |
|---|---|
| Pool config | `/usr/local/etc/zfs-das.conf` |
| Encryption key | `/etc/zfs/keys/<pool>.key` |
| Auto-mount daemon plist | `/Library/LaunchDaemons/com.local.zfs.automount.plist` |
| Auto-mount script | `/usr/local/bin/zfs-automount.sh` |
| SwiftBar plugins | `~/Library/Application Support/SwiftBar/Plugins/` |

## Uninstall

```bash
# Stop and remove LaunchDaemon
sudo launchctl unload /Library/LaunchDaemons/com.local.zfs.automount.plist
sudo rm /Library/LaunchDaemons/com.local.zfs.automount.plist
sudo rm /usr/local/bin/zfs-automount.sh

# Export pool (unmounts, data preserved)
sudo zpool export mypool

# Remove SwiftBar plugins
rm ~/Library/Application\ Support/SwiftBar/Plugins/zfs-*.sh

# Remove config
sudo rm /usr/local/etc/zfs-das.conf
```

To permanently destroy all data: `sudo zpool destroy mypool`

## See Also

- [ENCRYPTION.md](./ENCRYPTION.md) — Key management and recovery
- [MONITORING.md](./MONITORING.md) — SwiftBar menu bar monitoring
- [TIME_MACHINE.md](./TIME_MACHINE.md) — Time Machine over ZFS
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) — Common issues
