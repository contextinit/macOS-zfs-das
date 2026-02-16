#!/bin/bash

###############################################################################
# ZFS Encryption Setup Script for macOS
# 
# Purpose: Interactive wizard to set up encryption for ZFS datasets
#          Generates keys, configures secure storage, and encrypts datasets
#
# Usage: sudo ./setup-encryption.sh
#
# Author: macOS ZFS DAS Project
# License: MIT
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ZFS binary paths
ZFS_BIN_PATH="/usr/local/zfs/bin"
ZPOOL="$ZFS_BIN_PATH/zpool"
ZFS="$ZFS_BIN_PATH/zfs"

# Key storage directory
KEY_DIR="/etc/zfs/keys"

# Functions
print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if OpenZFS is installed
check_zfs_installed() {
    if [ ! -f "$ZPOOL" ]; then
        print_error "OpenZFS not found at $ZFS_BIN_PATH"
        exit 1
    fi
}

# Create key directory if it doesn't exist
setup_key_directory() {
    if [ ! -d "$KEY_DIR" ]; then
        print_info "Creating key directory: $KEY_DIR"
        mkdir -p "$KEY_DIR"
        chmod 700 "$KEY_DIR"
        chown root:wheel "$KEY_DIR"
        print_success "Key directory created"
    else
        print_success "Key directory exists: $KEY_DIR"
    fi
}

# Generate encryption key
generate_key() {
    local dataset="$1"
    local key_file="$KEY_DIR/${dataset//\//_}.key"
    
    print_info "Generating 256-bit encryption key..."
    
    # Generate random key
    dd if=/dev/random of="$key_file" bs=32 count=1 2>/dev/null
    
    # Set secure permissions
    chmod 600 "$key_file"
    chown root:wheel "$key_file"
    
    print_success "Key generated: $key_file"
    echo "$key_file"
}

# Encrypt existing dataset
encrypt_dataset() {
    local dataset="$1"
    local key_file="$2"
    
    print_info "Encrypting dataset: $dataset"
    
    # Create encrypted dataset with properties
    $ZFS set encryption=aes-256-gcm "$dataset" 2>/dev/null || {
        # If dataset exists and isn't encrypted, we need to recreate it
        print_warning "Dataset exists. Creating encrypted child dataset instead."
        local encrypted_name="${dataset}_encrypted"
        
        $ZFS create -o encryption=aes-256-gcm \
                    -o keyformat=raw \
                    -o keylocation="file://$key_file" \
                    "$encrypted_name"
        
        print_success "Created encrypted dataset: $encrypted_name"
        echo "$encrypted_name"
        return
    }
    
    # Set key properties
    $ZFS set keyformat=raw "$dataset"
    $ZFS set keylocation="file://$key_file" "$dataset"
    
    print_success "Dataset encrypted successfully"
    echo "$dataset"
}

# Create new encrypted dataset
create_encrypted_dataset() {
    local dataset="$1"
    local key_file="$2"
    
    print_info "Creating encrypted dataset: $dataset"
    
    $ZFS create -o encryption=aes-256-gcm \
                -o keyformat=raw \
                -o keylocation="file://$key_file" \
                "$dataset"
    
    if [ $? -eq 0 ]; then
        print_success "Encrypted dataset created: $dataset"
    else
        print_error "Failed to create encrypted dataset"
        return 1
    fi
}

# Backup key
backup_key() {
    local key_file="$1"
    local dataset="$2"
    
    echo ""
    print_header "Key Backup"
    
    print_warning "IMPORTANT: Back up this encryption key!"
    echo ""
    echo "Without this key, your data will be permanently inaccessible."
    echo ""
    echo "Key file: $key_file"
    echo ""
    echo "Backup options:"
    echo "  1. Copy to USB drive (recommended)"
    echo "  2. Print key as QR code"
    echo "  3. Store in password manager"
    echo "  4. Write down key fingerprint"
    echo ""
    
    read -p "Display key fingerprint? (y/n): " SHOW_FP
    
    if [ "$SHOW_FP" = "y" ] || [ "$SHOW_FP" = "Y" ]; then
        echo ""
        print_info "Key fingerprint (SHA256):"
        shasum -a 256 "$key_file"
        echo ""
        print_warning "Save this fingerprint to verify backup integrity"
    fi
    
    echo ""
    read -p "Have you backed up the key? Type 'YES' to continue: " CONFIRM
    
    if [ "$CONFIRM" != "YES" ]; then
        print_error "Setup cancelled. Please back up the key before continuing."
        exit 1
    fi
}

# Main script
clear
print_header "ZFS Encryption Setup Wizard"

check_root
check_zfs_installed
setup_key_directory

echo "This wizard will set up AES-256 encryption for your ZFS datasets."
echo ""
print_warning "Important notes:"
echo "  • Encryption keys will be stored in $KEY_DIR"
echo "  • Keys are required to access encrypted data"
echo "  • ALWAYS back up your keys securely"
echo "  • Lost keys = lost data (no recovery possible)"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
clear

# Step 1: Select Pool
print_header "Step 1: Select Pool"

echo "Available ZFS pools:"
echo ""
$ZPOOL list -H -o name
echo ""

read -p "Enter pool name to encrypt: " POOL_NAME

if ! $ZPOOL list "$POOL_NAME" &>/dev/null; then
    print_error "Pool '$POOL_NAME' not found"
    exit 1
fi

print_success "Pool: $POOL_NAME"
echo ""

# Step 2: Select Datasets
print_header "Step 2: Select Datasets"

echo "Available datasets in $POOL_NAME:"
echo ""
$ZFS list -H -o name -r "$POOL_NAME"
echo ""

echo "Which datasets do you want to encrypt?"
echo "  1. All datasets (recommended)"
echo "  2. Only /backups"
echo "  3. Only /data"
echo "  4. Custom selection"
echo ""

read -p "Select option (1-4): " DATASET_CHOICE

case "$DATASET_CHOICE" in
    1)
        DATASETS=("$POOL_NAME/data" "$POOL_NAME/backups")
        ;;
    2)
        DATASETS=("$POOL_NAME/backups")
        ;;
    3)
        DATASETS=("$POOL_NAME/data")
        ;;
    4)
        echo ""
        echo "Enter dataset names (space-separated):"
        read -p "Datasets: " CUSTOM_DATASETS
        read -ra DATASETS <<< "$CUSTOM_DATASETS"
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_info "Datasets to encrypt:"
for ds in "${DATASETS[@]}"; do
    echo "  • $ds"
done
echo ""

# Step 3: Encryption Method
print_header "Step 3: Encryption Method"

echo "Encryption configuration:"
echo "  Algorithm: AES-256-GCM"
echo "  Key format: Raw (256-bit random key)"
echo "  Key storage: File-based in $KEY_DIR"
echo ""

print_info "For each dataset, a unique encryption key will be generated."
echo ""

read -p "Continue? (y/n): " CONTINUE

if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    print_info "Setup cancelled"
    exit 0
fi

echo ""
print_header "Generating Keys and Encrypting Datasets..."

# Process each dataset
for dataset in "${DATASETS[@]}"; do
    echo ""
    print_info "Processing: $dataset"
    
    # Generate key
    KEY_FILE=$(generate_key "$dataset")
    
    # Check if dataset exists
    if $ZFS list "$dataset" &>/dev/null; then
        # Check if already encrypted
        ENCRYPTION=$($ZFS get -H -o value encryption "$dataset")
        
        if [ "$ENCRYPTION" = "off" ]; then
            print_warning "Dataset exists and is not encrypted"
            echo "  Note: Existing datasets cannot be encrypted in-place"
            echo "  Creating encrypted child dataset: ${dataset}_encrypted"
            
            create_encrypted_dataset "${dataset}_encrypted" "$KEY_FILE"
            
            print_info "To use encrypted storage:"
            echo "  1. Copy data from $dataset to ${dataset}_encrypted"
            echo "  2. Rename datasets when ready"
        else
            print_success "Dataset is already encrypted"
        fi
    else
        # Create new encrypted dataset
        create_encrypted_dataset "$dataset" "$KEY_FILE"
    fi
    
    # Backup reminder for each key
    backup_key "$KEY_FILE" "$dataset"
done

echo ""
print_header "Encryption Setup Complete!"

echo ""
print_success "Encryption has been configured for your datasets"
echo ""

print_info "Key storage:"
echo "  Directory: $KEY_DIR"
echo "  Permissions: 700 (root only)"
echo ""

print_info "Generated keys:"
ls -lh "$KEY_DIR"
echo ""

print_header "Next Steps"

echo "1. Configure auto-mount to load keys automatically:"
echo "   • Edit scripts/zfs-automount.sh"
echo "   • Verify POOL_NAME matches: $POOL_NAME"
echo "   • Install LaunchDaemon:"
echo "     sudo cp scripts/zfs-automount.sh /usr/local/bin/"
echo "     sudo cp configs/launchd/com.local.zfs.automount.plist /Library/LaunchDaemons/"
echo "     sudo launchctl load /Library/LaunchDaemons/com.local.zfs.automount.plist"
echo ""

echo "2. Back up your encryption keys:"
echo "   • Copy $KEY_DIR to secure offline storage"
echo "   • Use a password manager"
echo "   • Store on encrypted USB drive"
echo ""

print_warning "CRITICAL: Without encryption keys, your data is unrecoverable!"
echo ""

print_success "Encryption setup complete!"
