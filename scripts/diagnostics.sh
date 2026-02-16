#!/bin/bash

###############################################################################
# Diagnostic Tool
# 
# Purpose: Collect diagnostic information for troubleshooting
# Usage: ./scripts/diagnostics.sh [output_file]
###############################################################################

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

OUTPUT_FILE="${1:-zfs-diagnostics-$(date +%Y%m%d-%H%M%S).txt}"

echo -e "${BLUE}╔═══════════════════════════════════════╗"
echo "║   ZFS DAS Diagnostics                 ║"
echo -e "╚═══════════════════════════════════════╝${NC}"
echo ""
echo "Collecting diagnostic information..."
echo "Output file: $OUTPUT_FILE"
echo ""

# Start output file
cat > "$OUTPUT_FILE" << 'EOF'
╔═══════════════════════════════════════╗
║   ZFS DAS Diagnostic Report           ║
╚═══════════════════════════════════════╝

EOF

echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# System Information
echo "[1/10] System information..." 
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "SYSTEM INFORMATION" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "macOS Version: $(sw_vers -productVersion)" >> "$OUTPUT_FILE"
echo "Build: $(sw_vers -buildVersion)" >> "$OUTPUT_FILE"
echo "Hostname: $(hostname)" >> "$OUTPUT_FILE"
echo "Uptime: $(uptime)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# ZFS Version
echo "[2/10] ZFS version..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "ZFS VERSION" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
if [ -x "/usr/local/zfs/bin/zpool" ]; then
    /usr/local/zfs/bin/zpool --version >> "$OUTPUT_FILE" 2>&1
else
    echo "ZFS not found at /usr/local/zfs/bin/zpool" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Pool Status
echo "[3/10] Pool status..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "POOL STATUS" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
if [ -x "/usr/local/zfs/bin/zpool" ]; then
    /usr/local/zfs/bin/zpool list >> "$OUTPUT_FILE" 2>&1 || echo "No pools found" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    /usr/local/zfs/bin/zpool status >> "$OUTPUT_FILE" 2>&1 || echo "No pools to show status" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Dataset List
echo "[4/10] Dataset list..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "DATASETS" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
if [ -x "/usr/local/zfs/bin/zfs" ]; then
    /usr/local/zfs/bin/zfs list >> "$OUTPUT_FILE" 2>&1 || echo "No datasets found" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Disk Information
echo "[5/10] Disk information..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "DISKS" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
diskutil list >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Mount Points
echo "[6/10] Mount points..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "MOUNT POINTS" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
mount | grep -E "zfs|Volumes" >> "$OUTPUT_FILE" 2>&1 || echo "No ZFS mounts found" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# LaunchDaemons
echo "[7/10] LaunchDaemons..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "LAUNCHDAEMONS" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
launchctl list | grep zfs >> "$OUTPUT_FILE" 2>&1 || echo "No ZFS LaunchDaemons loaded" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Log Files
echo "[8/10] Recent log entries..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "LOG FILES" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "--- /var/log/zfs-automount.log ---" >> "$OUTPUT_FILE"
if [ -f "/var/log/zfs-automount.log" ]; then
    tail -50 /var/log/zfs-automount.log >> "$OUTPUT_FILE" 2>&1
else
    echo "Log file not found" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

echo "--- /var/log/zfs-maintenance.log ---" >> "$OUTPUT_FILE"
if [ -f "/var/log/zfs-maintenance.log" ]; then
    tail -50 /var/log/zfs-maintenance.log >> "$OUTPUT_FILE" 2>&1
else
    echo "Log file not found" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Configuration Files
echo "[9/10] Configuration..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "CONFIGURATION FILES" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for config_path in \
    "/usr/local/etc/zfs-das.conf" \
    "/etc/zfs-das.conf"; do
    
    if [ -f "$config_path" ]; then
        echo "--- $config_path ---" >> "$OUTPUT_FILE"
        # Redact sensitive info
        grep -v "EMAIL\|PASSWORD" "$config_path" >> "$OUTPUT_FILE" 2>&1 || true
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Encryption Keys (just count, not content)
echo "[10/10] Security audit..."
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "ENCRYPTION KEYS (security audit)" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ -d "/etc/zfs/keys" ]; then
    KEY_COUNT=$(ls -1 /etc/zfs/keys/*.key 2>/dev/null | wc -l | tr -d ' ')
    echo "Key files found: $KEY_COUNT" >> "$OUTPUT_FILE"
    
    if [ "$KEY_COUNT" -gt 0 ]; then
        echo "Key directory permissions: $(stat -f "%Sp" /etc/zfs/keys)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Key files (permissions only, no content):" >> "$OUTPUT_FILE"
        ls -l /etc/zfs/keys/*.key 2>/dev/null | awk '{print $1, $9}' >> "$OUTPUT_FILE" || true
    fi
else
    echo "No encryption keys directory found" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# End of report
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"
echo "END OF DIAGNOSTIC REPORT" >> "$OUTPUT_FILE"
echo "═══════════════════════════════════════" >> "$OUTPUT_FILE"

# Summary
echo ""
echo -e "${GREEN}✓ Diagnostics collection complete${NC}"
echo ""
echo "Report saved to: $OUTPUT_FILE"
echo "File size: $(du -h "$OUTPUT_FILE" | awk '{print $1}')"
echo ""
echo "You can review the report with:"
echo "  less $OUTPUT_FILE"
echo ""
echo "Or share it for troubleshooting (check for sensitive info first!):"
echo "  cat $OUTPUT_FILE"
