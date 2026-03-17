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

- ✅ **RAID-Z redundancy** (RAID-5/6 equivalent — survive 1–2 drive failures)
- ✅ **AES-256 encryption** (enterprise-grade security)
- ✅ **Time Machine support** (automated Mac backups over the network)
- ✅ **SwiftBar monitoring** (real-time health dashboard in your menu bar)
- ✅ **Auto-mount on boot** (works like native storage)
- ✅ **One-command installer** (guided setup wizard, no manual steps)
- ✅ **$0 recurring costs** (no cloud subscriptions, fully self-hosted)

**Perfect for:** Photographers, developers, video editors, and privacy-conscious users who need reliable, secure, local storage.

---

## 🎯 The Problem We're Solving

### What macOS Doesn't Offer:

- ❌ **No RAID-5/6 support** — Can't use parity-based redundancy on Mac
- ❌ **No native encryption for external drives** — FileVault only works on boot drives
- ❌ **Expensive NAS alternatives** — Network storage adds complexity, cost, and security risks
- ❌ **Cloud dependency** — Subscription fees, privacy concerns, upload limits

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
| DAS Enclosure (4-bay) | $150–300         | Sabrent, OWC, etc.
| 3x 8TB HDDs           | $300–450         | (~$100–150/drive)
| **Total**             | $600–750         | **One-time investment**
| **Usable capacity**   | **16TB**         | RAID-Z1 (2 drives data, 1 parity)

**ROI:** Break even in **6–18 months** vs cloud. Everything after is pure savings.

---

## 🚀 Quick Start

### Prerequisites

- Mac with Apple Silicon or Intel (macOS 14 Sonoma or later)
- DAS enclosure (Thunderbolt/USB-C) with 3+ drives connected
- [OpenZFS for macOS](https://openzfsonosx.github.io/) installed
- 30–45 minutes for the guided setup

### One-Command Installation

```bash
# 1. Clone this repository
git clone https://github.com/contextinit/macos-zfs-das.git
cd macos-zfs-das

# 2. Install OpenZFS if not already installed
#    Download the .pkg for your macOS version from:
#    https://openzfsonosx.github.io/

# 3. Run the interactive setup wizard
sudo bash scripts/setup.sh
```

The wizard guides you through **9 phases** and handles everything automatically:

| Phase | What happens |
|-------|-------------|
| 1 | Legal disclaimer — you review and accept before anything runs |
| 2 | System compatibility checks (macOS, OpenZFS, tools) |
| 3 | Drive identification — live `diskutil list` with safety prompts |
| 4 | Disk preparation commands shown as **text only** — you run them manually |
| 5 | Pool configuration (name, RAID type, compression, encryption) |
| 6 | Optional features (auto-mount, Time Machine, SwiftBar monitoring) |
| 7 | Full review of every setting + final confirmation before anything executes |
| 8 | Automated installation (pool creation, datasets, LaunchDaemon, SwiftBar) |
| 9 | Completion summary with next steps |

> **Disk safety:** The wizard never executes partition or erase commands on your behalf. All `diskutil` commands are printed as plain text for you to review and run manually in a separate terminal window. See the [safe testing guide](#-safe-testing-without-risk-to-your-system) for how to test with virtual disks first.

---

## 📖 Documentation

### Core Guides

- **[Complete Setup Guide](docs/SETUP.md)** — Step-by-step installation
- **[Encryption Configuration](docs/ENCRYPTION.md)** — AES-256 setup and key management
- **[Time Machine Setup](docs/TIME_MACHINE.md)** — Mac backups configuration
- **[Monitoring Setup](docs/MONITORING.md)** — SwiftBar dashboard installation
- **[Maintenance](docs/MAINTENANCE.md)** — Scrubs, snapshots, health checks

### Advanced Topics

- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** — Common issues and solutions
- **[User Experience Guide](docs/USER_EXPERIENCE.md)** — Tips and workflows

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Mac Mini / MacBook                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  SwiftBar    │  │ Auto-Mount   │  │ Time Machine │  │
│  │  Monitor     │  │ LaunchDaemon │  │   Backups    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │         │
│         └──────────────────┴──────────────────┘         │
│                            │                            │
│                  ┌─────────▼─────────┐                  │
│                  │   OpenZFS Pool    │                  │
│                  │   AES-256-GCM     │                  │
│                  │   media_pool      │                  │
│                  └─────────┬─────────┘                  │
│                            │                            │
└────────────────────────────┼────────────────────────────┘
                             │ Thunderbolt / USB-C
┌────────────────────────────▼────────────────────────────┐
│              Desktop Attached Storage (DAS)             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Drive 1 │  │  Drive 2 │  │  Drive 3 │  │ Drive 4│  │
│  │   8TB    │  │   8TB    │  │   8TB    │  │  8TB   │  │
│  │  (Data)  │  │  (Data)  │  │(Parity 1)│  │(Par. 2)│  │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
│              RAID-Z2 — Usable: 16TB                     │
│              Survives any 2 simultaneous drive failures │
└─────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 🧙 Guided Setup Wizard

- **9-phase interactive installer** — no manual command assembly needed
- **Drive safety guardrails** — disk prep commands shown as text only, never auto-executed
- **Inline validation** — pool names, disk identifiers, and quotas validated before any command runs
- **Full review screen** — see every setting and the exact `zpool create` command before committing
- **Typed confirmations** at every destructive step (not just Enter)

### 🔐 Enterprise Security

- **AES-256-GCM encryption** at rest — keys generated with `/dev/random`
- **Key stored at** `/etc/zfs/keys/<poolname>.key` (root-only, `chmod 600`)
- **Shell script hardening** — `set -euo pipefail` throughout, no unquoted variables, Bash arrays for disk paths
- **AppleScript injection prevention** in notification scripts
- **Input validation** mirrored between wizard UI and shell scripts

### 💪 Reliability

- **RAID-Z1/Z2/Z3** — survive 1, 2, or 3 simultaneous drive failures
- **Checksumming** — detects and corrects silent data corruption
- **Copy-on-write** — prevents data loss during writes
- **Snapshots** — point-in-time recovery
- **Monthly scrubbing** — automated integrity checks via LaunchDaemon

### 📊 SwiftBar Monitoring (Bundled — No Homebrew Required)

SwiftBar ([MIT License, Ameba Labs](THIRD-PARTY-LICENSES.md)) is downloaded automatically from GitHub Releases by the installer. Two plugin levels are included:

**Basic Monitor** (`zfs-monitor.30s.sh`):
- Pool health, capacity %, drive status, scrub progress, Time Machine status
- Clickable actions: import/export pool, start scrub, start backup

**Advanced Monitor** (`zfs-advanced.30s.sh`):
- Everything in Basic, plus:
- Unicode capacity bars with trend arrows (↗ ↘ →) from historical cache
- ARC cache size and utilisation
- Per-dataset compression ratios and encryption status
- Snapshot count with create/list/delete actions
- Adaptive dark/light mode colours via `$OS_APPEARANCE`
- SF Symbols menu bar icon (macOS 11+)

Both plugins refresh every 30 seconds and read from `~/.config/zfs-das.conf` or `/usr/local/etc/zfs-das.conf`.

### 🎯 Seamless macOS Integration

- **Auto-mount on boot** via LaunchDaemon — works like native storage
- **Time Machine support** — SMB share with ZFS quota per Mac
- **Multi-Mac support** — share across your devices
- **Menu bar monitoring** — real-time health at a glance

---

## 🛠️ What's Included

### Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | **Main installer** — 9-phase interactive onboarding wizard |
| `create-pool.sh` | Standalone pool creation wizard |
| `setup-encryption.sh` | AES-256 key generation and dataset encryption |
| `setup-monitoring.sh` | Interactive SwiftBar configuration |
| `install-swiftbar.sh` | Downloads latest SwiftBar from GitHub, installs plugins |
| `setup-timemachine.sh` | Time Machine sparse bundle and SMB share setup |
| `zfs-automount.sh` | Boot-time pool import and key loading |
| `zfs-maintenance.sh` | Monthly scrub scheduling and health checks |
| `check-prerequisites.sh` | Pre-flight system compatibility check |
| `diagnostics.sh` | Gather system info for troubleshooting |
| `health-check.sh` | Quick pool and drive health summary |
| `backup-helper.sh` | Snapshot creation and management |
| `quick-snapshot.sh` | One-shot snapshot with timestamp |
| `security-audit.sh` | Review key permissions and encryption status |
| `trigger-scrub.sh` | Manually kick off a pool scrub |

### SwiftBar Plugins

| Plugin | Level | Key features |
|--------|-------|-------------|
| `zfs-monitor.30s.sh` | Basic | Health, capacity, drives, scrub, Time Machine |
| `zfs-advanced.30s.sh` | Advanced | + ARC stats, trend arrows, capacity bars, snapshots, encryption |

### Configuration

- `configs/zfs-das.conf.example` — annotated configuration template
- `configs/launchd/` — LaunchDaemon plists for auto-mount, health checks, and maintenance

---

## 🧪 Safe Testing Without Risk to Your System

You can test the entire setup — including pool creation, encryption, drive failure simulation, and monitoring — using **sparse disk images** (virtual drives backed by files in `/tmp`). Nothing touches your real partitions.

```bash
# Create 4 virtual 2 GB drives
mkdir -p /tmp/zfs-test
for i in a b c d; do
  hdiutil create -size 2g -type SPARSE -layout NONE -o /tmp/zfs-test/disk-$i
  hdiutil attach -nomount /tmp/zfs-test/disk-$i.sparseimage
done

# See which /dev/diskN numbers were assigned
diskutil list | grep "disk image"

# Feed those disk numbers to the setup wizard when prompted
sudo bash scripts/setup.sh

# Full cleanup when done
sudo /usr/local/zfs/bin/zpool destroy test_pool
for dev in $(hdiutil info | grep '/tmp/zfs-test' | awk '{print $1}'); do
  hdiutil detach "$dev" -force
done
rm -rf /tmp/zfs-test
```

---

## 🔧 Hardware Recommendations

### DAS Enclosures (4-Bay)

**Thunderbolt (Fastest):**
- OWC Mercury Elite Pro Quad ($300) — Thunderbolt 3
- Akitio Thunder3 Quad ($250) — Thunderbolt 3

**USB-C (Budget-Friendly):**
- Sabrent 4-Bay ($150) — USB 3.2 Gen 2
- ORICO 4-Bay ($120) — USB 3.1

### Hard Drives

**NAS-Grade (Recommended):**
- WD Red Plus 8TB (~$150)
- Seagate IronWolf 8TB (~$140)
- Toshiba N300 8TB (~$130)

**Cost-Effective:**
- WD Blue 8TB (~$120)
- Seagate BarraCuda 8TB (~$110)

> Buy drives from different batches or manufacturers to reduce the risk of correlated failures.

### Minimum Requirements

- **Mac:** M1/M2/M3/M4 or Intel Mac (2018+)
- **macOS:** Sonoma (14.0) or newer
- **RAM:** 8GB+ (16GB recommended for ARC cache)
- **Connection:** Thunderbolt 3/4 or USB 3.1+
- **Drives:** 3+ identical capacity (4+ recommended for RAID-Z2)

---

## 📈 Performance

### Real-World Benchmarks

**Mac Mini M4 + Sabrent DAS + 3× 8TB WD Red**

| Operation | Speed | Notes |
|-----------|-------|-------|
| Sequential Read | ~400 MB/s | Limited by USB 3.2 |
| Sequential Write | ~350 MB/s | RAID-Z parity overhead |
| Random Read | ~120 MB/s | Depends on drive RPM |
| Random Write | ~80 MB/s | RAID-Z parity calc |
| Time Machine Backup | ~150 MB/s | Over SMB from MacBook |

> Thunderbolt connections can reach 800–1200 MB/s with SSD-based arrays.

---

## 🌍 Use Cases

### 👨‍💻 Developers
Local Git repositories, Docker volumes, build artifacts, database backups, CI/CD caches

### 📷 Photographers
RAW photo libraries, Lightroom catalogs, project archives, client deliverables, automated backups

### 🎬 Video Editors
4K/8K footage storage, Final Cut Pro libraries, DaVinci Resolve caches, render outputs

### 🏠 Home Users
Family photo/video archives, Time Machine backups for multiple Macs, personal cloud alternative

---

## 🔒 Security & Privacy

1. **Offline by default** — no internet connection required to use your storage
2. **AES-256-GCM encryption** — keys never leave your machine
3. **No cloud sync** — your data never leaves your control
4. **Hardened shell scripts** — `set -euo pipefail`, validated inputs, no injection vectors
5. **No vendor lock-in** — open standards (ZFS, SMB)

Privacy benefits:
- ✅ No third-party access to your files
- ✅ No data mining or scanning
- ✅ No account breaches or vendor terms changes
- ✅ Full GDPR/CCPA compliance — you control everything

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Areas for Contribution

- 📝 Documentation improvements
- 🐛 Bug fixes
- 🧪 Testing on different hardware configurations
- 🌍 Additional RAID configuration examples
- 📊 Performance benchmarks on new Mac hardware

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **[OpenZFS on macOS](https://github.com/openzfsonosx/openzfs)** — For the ZFS implementation on macOS (CDDL-1.0)
- **[SwiftBar](https://github.com/swiftbar/SwiftBar)** (Copyright 2020 Ameba Labs, MIT License) — The menu bar plugin runtime used for ZFS monitoring
- **Community** — For testing, feedback, and hardware reports

See [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md) for full license texts.

---

## 🆘 Support

- **Issues:** [GitHub Issues](https://github.com/contextinit/macos-zfs-das/issues)
- **Discussions:** [GitHub Discussions](https://github.com/contextinit/macos-zfs-das/discussions)
- **Docs:** [docs/](docs/)

---

## ⚠️ Disclaimer

This project involves disk operations that can result in **permanent, unrecoverable data loss** if performed incorrectly. The authors and contributors accept **no legal responsibility** for data loss, hardware damage, or system instability resulting from use of this software.

Before proceeding always:
- ✅ Back up all important data
- ✅ Verify every disk identifier before running any command
- ✅ Test with virtual disks first (see [Safe Testing](#-safe-testing-without-risk-to-your-system))
- ✅ Read the full disclaimer presented by the setup wizard

**Use at your own risk.**

---

## 🗺️ Roadmap

- [x] ~~Automated installer script~~ — `setup.sh` 9-phase wizard (v1.1)
- [x] ~~SwiftBar bundled install~~ — no Homebrew required (v1.1)
- [ ] Snapshot management UI
- [ ] Email/Slack alerting on pool health events
- [ ] Multi-pool support in monitoring plugins
- [ ] Hot spare configuration wizard
- [ ] Remote replication setup guide
- [ ] Docker container support

---

**Made with ❤️ by the community, for the community**

*Star ⭐ this repo if you find it useful!*
