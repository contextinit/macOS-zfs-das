# 🗄️ macOS ZFS DAS Solution

**Enterprise-grade encrypted storage for Mac using Desktop Attached Storage (DAS) and OpenZFS**

[![GitHub Stars](https://img.shields.io/github/stars/contextinit/macos-zfs-das?style=social)](https://github.com/contextinit/macos-zfs-das)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Issues](https://img.shields.io/github/issues/contextinit/macos-zfs-das)](https://github.com/contextinit/macos-zfs-das/issues)
[![macOS](https://img.shields.io/badge/macOS-14%2B-green)](https://www.apple.com/macos/)
[![OpenZFS](https://img.shields.io/badge/OpenZFS-2.3.1-orange)](https://openzfsonosx.github.io/)

---

## 📋 TL;DR

Transform a simple external hard drive enclosure into a **secure, encrypted, redundant storage system** for your Mac with:

- ✅ **RAID-5 redundancy** (lose 1 drive, keep your data)
- ✅ **AES-256 encryption** (enterprise-grade security)
- ✅ **Time Machine support** (automated Mac backups)
- ✅ **SwiftBar monitoring** (real-time health dashboard)
- ✅ **Auto-mount on boot** (works like native storage)
- ✅ **$0 recurring costs** (no cloud subscriptions, fully self-hosted)

**Perfect for:** Photographers, developers, video editors, and privacy-conscious users who need reliable, secure, local storage.

---

## 🎯 The Problem We're Solving

### What macOS Doesn't Offer:

- ❌ **No RAID-5/6 support** - Can't use parity-based redundancy on Mac
- ❌ **No native encryption for external drives** - FileVault only works on boot drives
- ❌ **Expensive NAS alternatives** - Network storage adds complexity, cost, and security risks
- ❌ **Cloud dependency** - Subscription fees, privacy concerns, upload limits

### What You Get Instead:

A **self-hosted, encrypted, redundant storage solution** that:
- Costs **$0/month** after initial hardware purchase
- Keeps **100% of your data offline** (no cloud exposure)
- Survives **drive failures** without data loss
- Works **exactly like native Mac storage** (seamless integration)
- Provides **Time Machine backups** for multiple Macs
- Includes **professional monitoring** via menu bar

---

## 💰 Cost Comparison

### Cloud Storage (Annual Costs)

| Service   | 2TB     | 5TB     | 10TB    | 20TB    |
|---------  |---------|---------|---------|---------|
| iCloud+   | $144/yr | N/A     | N/A     | N/A     |
| Dropbox   | $144/yr | N/A     | $240/yr | $480/yr |
| Backblaze | $84/yr  | $168/yr | $336/yr | $672/yr |
| *Total*   | $840+   | $1680+  | $2400+  | $4800+  |

### This Solution (One-Time)

| Component             | Cost             | Notes 
|---------------------  |------------------|-------
| DAS Enclosure (4-bay) | $150-300         | Sabrent, OWC, etc. 
| 3x 8TB HDDs           | $300-450         | (~$100-150/drive) 
| **Total**             | $600-750         | **One-time investment** 
| **Usable capacity**   | **16TB**         | RAID-5 (2 drives data, 1 parity) 

**ROI:** Break even in **6-18 months** vs cloud. Everything after is pure savings.

---

## 🚀 Quick Start

### Prerequisites

- Mac with Apple Silicon or Intel (macOS 14+)
- DAS enclosure (Thunderbolt/USB-C) with 3+ drives
- 30 minutes of setup time

### Installation (5 Steps)

```bash
# 1. Clone this repository
git clone https://github.com/contextinit/macos-zfs-das.git
cd macos-zfs-das

# 2. Install OpenZFS
# Download from: https://openzfsonosx.github.io/
# Install the .pkg file for your macOS version

# 3. Create your ZFS pool
sudo ./scripts/create-pool.sh

# 4. Set up encryption keys
sudo ./scripts/setup-encryption.sh

# 5. Configure auto-mount
sudo cp scripts/zfs-automount.sh /usr/local/bin/
sudo cp configs/launchd/com.local.zfs.automount.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.local.zfs.automount.plist
```

**That's it!** Your encrypted ZFS pool will auto-mount on boot.

---

## 📖 Full Documentation

### Core Guides

- **[Complete Setup Guide](docs/SETUP.md)** - Step-by-step installation
- **[Encryption Configuration](docs/ENCRYPTION.md)** - AES-256 setup and key management
- **[Time Machine Setup](docs/TIME_MACHINE.md)** - Mac backups configuration
- **[Auto-Mount Configuration](docs/AUTO_MOUNT.md)** - Boot-time automation
- **[Monitoring Setup](docs/MONITORING.md)** - SwiftBar dashboard installation

### Advanced Topics

- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Drive Replacement](docs/DRIVE_REPLACEMENT.md)** - Handling failed drives
- **[Performance Tuning](docs/PERFORMANCE.md)** - Optimization tips
- **[Backup Strategies](docs/BACKUP_STRATEGIES.md)** - Multi-Mac setups
- **[Remote Access](docs/REMOTE_ACCESS.md)** - VPN and secure access

### Reference

- **[ZFS Commands Cheat Sheet](docs/ZFS_COMMANDS.md)**
- **[Script Reference](docs/SCRIPTS.md)**
- **[FAQ](docs/FAQ.md)**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Mac Mini / MacBook                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  SwiftBar    │  │ Auto-Mount   │  │ Time Machine │   │
│  │  Monitor     │  │   Script     │  │   Backups    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│         │                  │                  │         │
│         └──────────────────┴──────────────────┘         │
│                            │                            │
│                  ┌─────────▼─────────┐                  │
│                  │   OpenZFS Pool    │                  │
│                  │   (AES-256)       │                  │
│                  │   media_pool      │                  │
│                  └─────────┬─────────┘                  │
│                            │                            │
└────────────────────────────┼────────────────────────────┘
                             │ Thunderbolt/USB-C
                             │
┌────────────────────────────▼────────────────────────────┐
│              Desktop Attached Storage (DAS)             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐   │
│  │  Drive 1 │  │  Drive 2 │  │  Drive 3 │  │ Empty  │   │
│  │   8TB    │  │   8TB    │  │   8TB    │  │  Bay   │   │
│  │  (Data)  │  │  (Data)  │  │ (Parity) │  │(Spare) │   │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘   │
│                                                         │
│              RAID-Z1 (RAID-5 equivalent)                │
│              Usable: 16TB, Redundancy: 1 drive          │
└─────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 🔐 Enterprise Security

- **AES-256 encryption** at rest
- **Encrypted key storage** with password protection
- **Per-dataset encryption** for granular control
- **No cloud exposure** - 100% offline

### 💪 Reliability

- **RAID-Z1** (RAID-5) - Survives single drive failure
- **Checksumming** - Detects and corrects silent data corruption
- **Copy-on-write** - Prevents data loss during writes
- **Snapshots** - Point-in-time recovery
- **Monthly scrubbing** - Automated integrity checks

### 🎯 Seamless Integration

- **Auto-mount on boot** - Works like native Mac storage
- **Time Machine support** - Standard Mac backups
- **Multi-Mac support** - Share across your devices
- **Network access** - Optional SMB sharing
- **Menu bar monitoring** - Real-time health status

### 📊 Professional Monitoring

- Real-time pool health
- Capacity trending with alerts
- Individual drive status
- Scrub progress tracking
- Time Machine backup status
- I/O performance metrics
- Historical data tracking

---

## 🛠️ What's Included

### Scripts

- `zfs-automount.sh` - Boot-time pool import with encryption
- `zfs-maintenance.sh` - Monthly health checks and scrubbing
- `setup-monitoring.sh` - SwiftBar configuration
- `setup-timemachine.sh` - Time Machine helper
- `create-pool.sh` - Interactive pool creation

### SwiftBar Plugins

- `zfs-monitor.30s.sh` - Basic monitoring
- `zfs-advanced.30s.sh` - Advanced with trending

### Documentation

- Complete setup guides
- Troubleshooting help
- Performance tuning
- Backup strategies
- ZFS command reference

### Configuration Files

- LaunchDaemon plists
- Key management examples
- Time Machine configs

---

## 🔧 Hardware Recommendations

### DAS Enclosures (4-Bay)

**Thunderbolt (Fastest):**
- OWC Mercury Elite Pro Quad ($300) - Thunderbolt 3
- Akitio Thunder3 Quad ($250) - Thunderbolt 3

**USB-C (Budget-Friendly):**
- Sabrent 4-Bay ($150) - USB 3.2 Gen 2
- ORICO 4-Bay ($120) - USB 3.1

### Hard Drives

**NAS-Grade (Recommended):**
- WD Red Plus 8TB (~$150)
- Seagate IronWolf 8TB (~$140)
- Toshiba N300 8TB (~$130)

**Cost-Effective:**
- WD Blue 8TB (~$120)
- Seagate BarraCuda 8TB (~$110)

**Note:** Buy drives from different batches/manufacturers to avoid correlated failures.

### Minimum Requirements

- **Mac:** M1/M2/M3/M4 or Intel Mac (2018+)
- **macOS:** Sonoma (14.0) or newer
- **RAM:** 8GB+ (16GB recommended)
- **Connection:** Thunderbolt 3/4 or USB 3.1+
- **Drives:** 3x identical capacity (4+ recommended)

---

## 📈 Performance

### Real-World Benchmarks

**Mac Mini M4 + Sabrent DAS + 3x 8TB WD Red**

| Operation | Speed | Notes |
|-----------|-------|-------|
| Sequential Read | ~400 MB/s | Limited by USB 3.2 |
| Sequential Write | ~350 MB/s | RAID-5 parity overhead |
| Random Read | ~120 MB/s | Depends on drive RPM |
| Random Write | ~80 MB/s | RAID-5 parity calc |
| Time Machine Backup | ~150 MB/s | Over SMB from MacBook |

**Note:** Thunderbolt connections can reach 800-1200 MB/s with SSD-based arrays.

---

## 🌍 Use Cases

### 👨‍💻 Developers

- Local Git repositories
- Docker volumes
- Build artifacts
- Database backups
- CI/CD caches

### 📷 Photographers

- RAW photo libraries
- Lightroom catalogs
- Project archives
- Client deliverables
- Automated backups

### 🎬 Video Editors

- 4K/8K footage storage
- Final Cut Pro libraries
- DaVinci Resolve caches
- Render outputs
- Project versioning

### 🏠 Home Users

- Family photo/video archives
- Time Machine backups
- Music libraries
- Document storage
- Personal cloud alternative

---

## 🔒 Security & Privacy

### What Makes This Secure?

1. **Offline by default** - No internet connection required
2. **AES-256 encryption** - Military-grade protection
3. **No cloud sync** - Your data never leaves your control
4. **Optional VPN access** - Secure remote access via WireGuard
5. **No vendor lock-in** - Open standards (ZFS, SMB)

### Privacy Benefits

- ✅ No third-party access to your files
- ✅ No data mining or scanning
- ✅ No terms of service changes
- ✅ No account breaches
- ✅ No government back-doors
- ✅ Full GDPR/CCPA compliance (you control everything)

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Areas for Contribution

- 📝 Documentation improvements
- 🐛 Bug fixes
- ✨ New features
- 🧪 Testing on different hardware
- 🌍 Translations
- 📊 Performance optimizations

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **OpenZFS Team** - For the amazing ZFS implementation
- **SwiftBar** - For the excellent menu bar framework
- **Community** - For testing and feedback

---

## 🆘 Support

- **Documentation:** [Full Docs](docs/)
- **Issues:** [GitHub Issues](https://github.com/contextinit/macos-zfs-das/issues)
- **Discussions:** [GitHub Discussions](https://github.com/contextinit/macos-zfs-das/discussions)

---

## ⚠️ Disclaimer

This project involves disk operations that can result in data loss if performed incorrectly. Always:

- ✅ Backup your data before starting
- ✅ Test on non-critical data first
- ✅ Verify backups before deleting originals
- ✅ Read the documentation thoroughly

**Use at your own risk.** The authors are not responsible for any data loss.

---

## 🗺️ Roadmap

- [ ] Automated installer script
- [ ] GUI configuration tool
- [ ] Snapshot management UI
- [ ] Email/Slack alerting
- [ ] Multi-pool support
- [ ] Hot spare configuration
- [ ] Remote replication setup
- [ ] Docker container support

---

**Made with ❤️ by the community, for the community**

*Star ⭐ this repo if you find it useful!*
