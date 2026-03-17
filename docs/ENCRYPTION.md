# Encryption Configuration Guide

## 🔐 Overview

This guide covers everything you need to know about encrypting your ZFS datasets with AES-256 encryption, including key generation, secure storage, backup strategies, and recovery procedures.

## Table of Contents

- [Why Use Encryption?](#why-use-encryption)
- [Quick Start](#quick-start)
- [Encryption Specifications](#encryption-specifications)
- [Key Generation](#key-generation)
- [Key Storage](#key-storage)
- [Dataset Encryption Setup](#dataset-encryption-setup)
- [Key Backup Strategies](#key-backup-strategies)
- [Key Security Best Practices](#key-security-best-practices)
- [Key Rotation](#key-rotation)
- [Recovery Procedures](#recovery-procedures)
- [Troubleshooting](#troubleshooting)

---

## Why Use Encryption?

### Security Benefits

- ✅ **Data at Rest Protection** - Data is encrypted on disk
- ✅ **Drive Theft Protection** - Stolen drives are unreadable
- ✅ **Secure Disposal** - Delete key instead of wiping drive
- ✅ **Compliance** - Meets regulatory requirements (GDPR, HIPAA, etc.)
- ✅ **No Performance Impact** - Hardware AES acceleration on modern CPUs

### When You Need Encryption

- Storing sensitive personal data
- Business/financial documents
- Medical records
- Source code/IP
- Portable drives (DAS that might be disconnected)
- Compliance requirements

---

## Quick Start

### Using the Interactive Setup Wizard (Recommended)

The easiest way to set up encryption is during the main setup wizard:

```bash
bash scripts/setup.sh
```

In **Phase 5**, choose whether to enable encryption. The wizard:
1. Generates a 256-bit AES key with `openssl rand`
2. Saves it to `/etc/zfs/keys/<pool>.key` with `0400` permissions
3. Displays a SHA-256 fingerprint and prompts you to confirm you have noted the key location
4. Creates the pool with `encryption=aes-256-gcm` and `keyformat=raw`
5. Configures the auto-mount LaunchDaemon to load the key at boot

### Using the Standalone Encryption Script

```bash
sudo ./scripts/setup-encryption.sh
```

The script will:
1. Select your ZFS pool
2. Choose datasets to encrypt
3. Generate encryption keys
4. Set up secure key storage
5. Encrypt your datasets
6. Guide you through key backup

---

## Encryption Specifications

### Algorithm Details

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Algorithm** | AES-256-GCM | Industry standard |
| **Key Size** | 256 bits (32 bytes) | Maximum security |
| **Mode** | GCM (Galois/Counter Mode) | Authenticated encryption |
| **Key Format** | Raw binary | Direct key material |
| **Key Generation** | `/dev/random` | Cryptographically secure |
| **Performance** | ~400-500 MB/s | Hardware accelerated |

### Security Properties

- **Confidentiality** - Data cannot be read without key
- **Integrity** - Tampering detected via authentication tags
- **Forward Secrecy** - Each block encrypted independently
- **No Padding Oracle** - GCM mode eliminates padding attacks

---

## Key Generation

### Automatic Generation (Recommended)

The `setup-encryption.sh` script generates secure keys automatically:

```bash
# Generates 256-bit key from /dev/random
dd if=/dev/random of=/etc/zfs/keys/dataset.key bs=32 count=1
```

### Manual Generation

If you need to generate keys manually:

```bash
# Create key directory
sudo mkdir -p /etc/zfs/keys
sudo chmod 700 /etc/zfs/keys
sudo chown root:wheel /etc/zfs/keys

# Generate key for a dataset
sudo dd if=/dev/random of=/etc/zfs/keys/media_pool_data.key bs=32 count=1

# Set secure permissions
sudo chmod 600 /etc/zfs/keys/media_pool_data.key
sudo chown root:wheel /etc/zfs/keys/media_pool_data.key
```

### Key Naming Convention

```
Pool: media_pool
Dataset: media_pool/data
Key file: /etc/zfs/keys/media_pool_data.key

Pool: backup_pool
Dataset: backup_pool/sensitive
Key file: /etc/zfs/keys/backup_pool_sensitive.key
```

Format: `{pool}_{dataset}.key` with `/` replaced by `_`

---

## Key Storage

### Directory Structure

```
/etc/zfs/
└── keys/                           # Key directory (700, root:wheel)
    ├── media_pool_data.key        # Dataset key (600, root:wheel)
    ├── media_pool_backups.key     # Another dataset (600, root:wheel)
    └── README.txt                  # Optional documentation
```

### Required Permissions

| Item | Owner | Group | Permissions | Octal |
|------|-------|-------|-------------|-------|
| `/etc/zfs/keys/` | root | wheel | `drwx------` | 700 |
| `*.key` files | root | wheel | `-rw-------` | 600 |

### Setting Permissions

```bash
# Fix directory permissions
sudo chmod 700 /etc/zfs/keys
sudo chown root:wheel /etc/zfs/keys

# Fix all key file permissions
sudo chmod 600 /etc/zfs/keys/*.key
sudo chown root:wheel /etc/zfs/keys/*.key
```

### Automatic Validation

The `zfs-automount.sh` script automatically validates permissions at boot:

- Checks directory permissions (should be 700)
- Checks key file permissions (should be 600)
- Verifies ownership (should be root:wheel)
- Detects world-readable keys
- Auto-fixes if running as root
- Logs all security warnings

---

## Dataset Encryption Setup

### Encrypt New Dataset

```bash
# Create encrypted dataset
sudo zfs create \
    -o encryption=aes-256-gcm \
    -o keyformat=raw \
    -o keylocation=file:///etc/zfs/keys/media_pool_data.key \
    media_pool/data

# Verify encryption
sudo zfs get encryption,keyformat,keylocation media_pool/data
```

### Encrypt Existing Dataset

> [!WARNING]
> Existing datasets cannot be encrypted in-place. You must create a new encrypted dataset and copy data.

```bash
# 1. Create encrypted dataset
sudo zfs create \
    -o encryption=aes-256-gcm \
    -o keyformat=raw \
    -o keylocation=file:///etc/zfs/keys/media_pool_data_encrypted.key \
    media_pool/data_encrypted

# 2. Copy data
sudo rsync -avP /Volumes/media_pool/data/ /Volumes/media_pool/data_encrypted/

# 3. Verify data integrity
diff -r /Volumes/media_pool/data/ /Volumes/media_pool/data_encrypted/

# 4. Swap datasets (when ready)
sudo zfs rename media_pool/data media_pool/data_old
sudo zfs rename media_pool/data_encrypted media_pool/data

# 5. Delete old unencrypted dataset (AFTER backup!)
sudo zfs destroy media_pool/data_old
```

### Inherit Encryption

Child datasets inherit encryption from parent:

```bash
# Parent is encrypted
sudo zfs create media_pool/data  # encrypted with its own key

# Children automatically encrypted
sudo zfs create media_pool/data/photos      # encrypted (inherited)
sudo zfs create media_pool/data/documents  # encrypted (inherited)

# Children can have their own keys
sudo zfs create \
    -o keyformat=raw \
    -o keylocation=file:///etc/zfs/keys/special.key \
    media_pool/data/top_secret
```

---

## Key Backup Strategies

> [!CAUTION]
> **Loss of encryption key = permanent data loss.** There is no recovery without the key.

### Strategy 1: Offline USB Drive (Recommended)

```bash
# 1. Prepare encrypted USB drive
diskutil list  # Find USB drive
diskutil eraseDisk JHFS+ "SecureBackup" GPTFormat /dev/diskX

# 2. Enable FileVault on USB
# (Use Disk Utility GUI or diskutil apfs enableFileVault)

# 3. Copy keys to USB
sudo cp -r /etc/zfs/keys /Volumes/SecureBackup/zfs-keys-backup-$(date +%Y%m%d)

# 4. Store USB in safe place (home safe, bank safe deposit box)
```

### Strategy 2: Password Manager

```bash
# 1. Generate key fingerprint
shasum -a 256 /etc/zfs/keys/*.key > /tmp/key-fingerprints.txt

# 2. Base64 encode keys for text storage
for key in /etc/zfs/keys/*.key; do
    echo "$(basename "$key"): $(base64 < "$key")"
done > /tmp/keys-b64.txt

# 3. Store in password manager (1Password, Bitwarden, etc.)
# - Store fingerprints in one entry
# - Store base64 keys in secure note

# 4. Securely delete temp files
srm -fv /tmp/key*.txt  # or rm -P on macOS
```

### Strategy 3: Paper Backup (QR Code)

```bash
# 1. Install qrencode (if using QR codes)
brew install qrencode

# 2. Generate QR code for each key
for key in /etc/zfs/keys/*.key; do
    base64 < "$key" | qrencode -o "$(basename "$key" .key).png"
done

# 3. Print QR codes and store in safe

# 4. Test QR code scanning
# Scan QR → base64 decode → verify fingerprint
```

### Strategy 4: Geographic Distribution

```bash
# Store key copies in multiple physical locations:
# 1. Primary: /etc/zfs/keys (on system)
# 2. Backup 1: USB drive in home safe
# 3. Backup 2: Password manager (cloud, encrypted)
# 4. Backup 3: Paper/QR code at trusted friend/family
# 5. Backup 4: Bank safe deposit box
```

### Key Backup Checklist

- [ ] Keys backed up to offline USB drive
- [ ] USB drive encrypted with FileVault
- [ ] Key fingerprints documented
- [ ] Backup stored in secure location
- [ ] Backup restoration tested successfully
- [ ] Family/colleagues know where keys are
- [ ] Recovery procedure documented

---

## Key Security Best Practices

### ✅ DO

- ✅ Keep keys in `/etc/zfs/keys/` with 600 permissions
- ✅ Set directory to 700, owned by root
- ✅ Back up keys to multiple secure locations
- ✅ Test recovery procedure periodically
- ✅ Use hardware-encrypted USBs for backups
- ✅ Store backups geographically distributed
- ✅ Document key locations for disaster recovery
- ✅ Use strong passwords on encrypted backups
- ✅ Rotate keys annually or after security events
- ✅ Verify key fingerprints after backup

### ❌ DON'T

- ❌ Store keys in home directory
- ❌ Email keys (even encrypted)
- ❌ Store keys in cloud without encryption
- ❌ Use weak permissions (644, 755, etc.)
- ❌ Store keys on same drive as encrypted data
- ❌ Forget to back up keys
- ❌ Store all backups in one location
- ❌ Share keys via unencrypted channels
- ❌ Store keys in version control (git)
- ❌ Use predictable key names in backups

---

## Key Rotation

### When to Rotate Keys

- Annually (proactive security)
- After employee termination
- After suspected compromise
- After hardware replacement
- For compliance requirements

### Rotation Procedure

```bash
# 1. Generate new key
sudo dd if=/dev/random of=/etc/zfs/keys/media_pool_data.key.new bs=32 count=1
sudo chmod 600 /etc/zfs/keys/media_pool_data.key.new

# 2. Change dataset key
sudo zfs change-key \
    -o keyformat=raw \
    -o keylocation=file:///etc/zfs/keys/media_pool_data.key.new \
    media_pool/data

# 3. Verify new key works
sudo zfs unload-key media_pool/data
sudo zfs load-key media_pool/data
sudo zfs mount media_pool/data

# 4. Backup new key
sudo cp /etc/zfs/keys/media_pool_data.key.new /Volumes/SecureBackup/

# 5. Securely delete old key
sudo srm /etc/zfs/keys/media_pool_data.key  # or rm -P
sudo mv /etc/zfs/keys/media_pool_data.key.new /etc/zfs/keys/media_pool_data.key

# 6. Update documentation
echo "Key rotated on $(date)" | sudo tee -a /etc/zfs/keys/ROTATION_LOG.txt
```

---

## Recovery Procedures

### Scenario 1: Lost Key File (Have Backup)

```bash
# 1. Copy key from backup
sudo cp /Volumes/SecureBackup/media_pool_data.key /etc/zfs/keys/

# 2. Set correct permissions
sudo chmod 600 /etc/zfs/keys/media_pool_data.key
sudo chown root:wheel /etc/zfs/keys/media_pool_data.key

# 3. Load key
sudo zfs load-key media_pool/data

# 4. Mount dataset
sudo zfs mount media_pool/data
```

### Scenario 2: System Reinstall

```bash
# 1. Install OpenZFS on new system
# Download from https://openzfsonosx.github.io/

# 2. Connect DAS with encrypted pool

# 3. Restore keys from backup
sudo mkdir -p /etc/zfs/keys
sudo cp /Volumes/SecureBackup/zfs-keys-backup-*/*.key /etc/zfs/keys/
sudo chmod 700 /etc/zfs/keys
sudo chmod 600 /etc/zfs/keys/*.key
sudo chown -R root:wheel /etc/zfs/keys

# 4. Import pool
sudo zpool import -d /dev media_pool

# 5. Load keys
sudo zfs load-key -a

# 6. Mount datasets
sudo zfs mount -a
```

### Scenario 3: Corrupted Key File

```bash
# Key file corrupted but have backup

# 1. Verify corruption
sha256sum /etc/zfs/keys/media_pool_data.key
# Compare with backup fingerprint

# 2. Replace with backup
sudo cp /Volumes/SecureBackup/media_pool_data.key /etc/zfs/keys/
sudo chmod 600 /etc/zfs/keys/media_pool_data.key

# 3. Reload key
sudo zfs unload-key media_pool/data
sudo zfs load-key media_pool/data
```

### Scenario 4: No Backup (Data Loss)

> [!CAUTION]
> **Without a key backup, your data is permanently lost**. There is no recovery.

**Prevention is the only solution:**
- Always maintain multiple key backups
- Test recovery procedure annually
- Document backup locations
- Use `setup-encryption.sh` which enforces backup verification

---

## Troubleshooting

### Key Won't Load

```bash
# Check key exists
ls -l /etc/zfs/keys/

# Check permissions
stat /etc/zfs/keys/*.key

# Try loading manually
sudo zfs load-key -L file:///etc/zfs/keys/media_pool_data.key media_pool/data

# Check for errors
sudo zfs load-key media_pool/data  # Will show error message
```

### Dataset Won't Mount

```bash
# Check if key is loaded
zfs get keystatus media_pool/data
# Should show: "available"

# If "unavailable", load key first
sudo zfs load-key media_pool/data

# Then mount
sudo zfs mount media_pool/data
```

### Permission Warnings

```bash
# Auto-fix with automount script
sudo /usr/local/bin/zfs-automount.sh

# Or manually fix
sudo chmod 700 /etc/zfs/keys
sudo chmod 600 /etc/zfs/keys/*.key
sudo chown -R root:wheel /etc/zfs/keys
```

### Verify Encryption

```bash
# Check encryption status
zfs get encryption,keyformat,keystatus,keylocation media_pool/data

# Should show:
# encryption: aes-256-gcm
# keyformat: raw
# keystatus: available
# keylocation: file:///etc/zfs/keys/media_pool_data.key
```

---

## Command Reference

### Key Management

```bash
# Load key
sudo zfs load-key media_pool/data

# Load all keys
sudo zfs load-key -a

# Unload key
sudo zfs unload-key media_pool/data

# Change key
sudo zfs change-key media_pool/data

# Check key status
zfs get keystatus media_pool/data
```

### Encryption Properties

```bash
# View encryption settings
zfs get encryption,keyformat,keylocation media_pool/data

# Set encryption on new dataset
sudo zfs create \
    -o encryption=aes-256-gcm \
    -o keyformat=raw \
    -o keylocation=file:///path/to/key \
    pool/dataset

# Inherit from parent
sudo zfs create -o encryption=on pool/dataset
```

---

## Security Checklist

Use this checklist to verify your encryption setup:

- [ ] Encryption enabled on all sensitive datasets
- [ ] Keys stored in `/etc/zfs/keys/`
- [ ] Directory permissions: 700 (drwx------)
- [ ] Key file permissions: 600 (-rw-------)
- [ ] All files owned by root:wheel
- [ ] Keys backed up to offline USB
- [ ] USB drive encrypted with FileVault
- [ ] Key fingerprints documented
- [ ] Secondary backup in secure location
- [ ] Recovery procedure tested
- [ ] Key locations documented for disaster recovery
- [ ] Annual key rotation scheduled
- [ ] Automatic permission validation enabled

---

## Additional Resources

- [OpenZFS Encryption Documentation](https://openzfs.github.io/openzfs-docs/man/8/zfs-load-key.8.html)
- [ZFS Encryption Best Practices](https://wiki.archlinux.org/title/ZFS#Encryption)
- [NIST AES Standards](https://csrc.nist.gov/publications/detail/fips/197/final)
- [macOS FileVault](https://support.apple.com/guide/mac-help/protect-data-on-your-mac-with-filevault-mh11785/)

---

**Remember:** Encryption is only secure if keys are properly managed. Always maintain backups!
