#!/bin/bash

# <xbar.title>ZFS Pool Monitor</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Your Name</xbar.author>
# <xbar.author.github>yourusername</xbar.author.github>
# <xbar.desc>Monitors ZFS pool health, capacity, and status</xbar.desc>
# <xbar.dependencies>openzfs</xbar.dependencies>
# <xbar.abouturl>https://github.com/openzfsonosx</xbar.abouturl>

# SwiftBar Metadata (refresh interval)
# <swiftbar.refreshInterval>30s</swiftbar.refreshInterval>

# Load configuration
CONFIG_LOADED=false
for config_path in \
    "/usr/local/etc/zfs-das.conf" \
    "/etc/zfs-das.conf" \
    "$HOME/.config/zfs-das.conf"; do
    if [ -f "$config_path" ]; then
        # shellcheck source=/dev/null
        source "$config_path"
        CONFIG_LOADED=true
        break
    fi
done

# Fallback defaults
if [ "$CONFIG_LOADED" = false ]; then
    POOL_NAME="media_pool"
    ZFS_BIN_PATH="/usr/local/zfs/bin"
fi

# ZFS binary paths
ZPOOL="$ZFS_BIN_PATH/zpool"
ZFS="$ZFS_BIN_PATH/zfs"

# Color codes for SwiftBar
COLOR_GREEN="#00C853"
COLOR_YELLOW="#FFB300"
COLOR_RED="#D50000"
COLOR_BLUE="#2979FF"
COLOR_GRAY="#616161"

# Icons (SF Symbols work great on macOS)
ICON_HEALTHY="🟢"
ICON_WARNING="🟡"
ICON_ERROR="🔴"
ICON_OFFLINE="⚫"
ICON_POOL="💾"
ICON_DATASET="📁"
ICON_BACKUP="⏱️"
ICON_SCRUB="🔍"
ICON_REFRESH="🔄"

# Function to get pool status
get_pool_status() {
    if ! $ZPOOL list "$POOL_NAME" &>/dev/null; then
        echo "offline"
        return
    fi
    
    local state=$($ZPOOL status "$POOL_NAME" | grep "state:" | awk '{print $2}')
    echo "$state"
}

# Function to get pool health icon and color
get_health_indicator() {
    local status=$1
    case "$status" in
        "ONLINE")
            echo "$ICON_HEALTHY"
            ;;
        "DEGRADED")
            echo "$ICON_WARNING"
            ;;
        "FAULTED"|"UNAVAIL")
            echo "$ICON_ERROR"
            ;;
        "offline")
            echo "$ICON_OFFLINE"
            ;;
        *)
            echo "❓"
            ;;
    esac
}

# Function to get pool capacity percentage
get_capacity() {
    if ! $ZPOOL list "$POOL_NAME" &>/dev/null; then
        echo "0"
        return
    fi
    $ZPOOL list -H -o capacity "$POOL_NAME" | tr -d '%'
}

# Function to get capacity color based on usage
get_capacity_color() {
    local cap=$1
    if [ "$cap" -lt 70 ]; then
        echo "$COLOR_GREEN"
    elif [ "$cap" -lt 85 ]; then
        echo "$COLOR_YELLOW"
    else
        echo "$COLOR_RED"
    fi
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -gt 1099511627776 ]; then
        echo "$(($bytes / 1099511627776))TB"
    elif [ "$bytes" -gt 1073741824 ]; then
        echo "$(($bytes / 1073741824))GB"
    else
        echo "$(($bytes / 1048576))MB"
    fi
}

# Function to check for errors
get_error_count() {
    if ! $ZPOOL status "$POOL_NAME" &>/dev/null; then
        echo "N/A"
        return
    fi
    
    local read_errors=$($ZPOOL status "$POOL_NAME" | grep "^$POOL_NAME" | awk '{print $3}')
    local write_errors=$($ZPOOL status "$POOL_NAME" | grep "^$POOL_NAME" | awk '{print $4}')
    local cksum_errors=$($ZPOOL status "$POOL_NAME" | grep "^$POOL_NAME" | awk '{print $5}')
    
    local total=$((read_errors + write_errors + cksum_errors))
    echo "$total"
}

# Function to check scrub status
get_scrub_status() {
    if ! $ZPOOL status "$POOL_NAME" &>/dev/null; then
        echo "Pool offline"
        return
    fi
    
    local scrub_line=$($ZPOOL status "$POOL_NAME" | grep "scan:")
    if echo "$scrub_line" | grep -q "scrub in progress"; then
        # Extract percentage
        local percent=$(echo "$scrub_line" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
        echo "In Progress: $percent"
    elif echo "$scrub_line" | grep -q "scrub repaired"; then
        # Last scrub completed
        local date=$(echo "$scrub_line" | grep -oE '[A-Z][a-z]+ [A-Z][a-z]+ [0-9]+ [0-9]+:[0-9]+:[0-9]+ [0-9]+')
        echo "Last: $date"
    elif echo "$scrub_line" | grep -q "none requested"; then
        echo "Never run"
    else
        echo "Unknown"
    fi
}

# Function to check Time Machine backup status
get_tm_status() {
    local tm_vol="${TM_VOLUME_NAME:-RMMacMM4}"
    if mount | grep -q "$tm_vol"; then
        local tm_dest=$(tmutil destinationinfo 2>/dev/null | grep "Mount Point" | grep "$tm_vol")
        if [ -n "$tm_dest" ]; then
            # Check last backup
            local last_backup=$(tmutil latestbackup 2>/dev/null)
            if [ -n "$last_backup" ]; then
                local backup_date=$(basename "$last_backup" | cut -d'-' -f1-3)
                echo "Active (Last: $backup_date)"
            else
                echo "Active (No backups yet)"
            fi
        else
            echo "Mounted, not configured"
        fi
    else
        echo "Not mounted"
    fi
}

# Main menu bar display
POOL_STATUS=$(get_pool_status)
HEALTH_ICON=$(get_health_indicator "$POOL_STATUS")
CAPACITY=$(get_capacity)
CAP_COLOR=$(get_capacity_color "$CAPACITY")

# Menu bar item (what shows in the menu bar)
echo "$HEALTH_ICON $POOL_NAME ${CAPACITY}% | color=$CAP_COLOR"
echo "---"

# Dropdown menu content
if [ "$POOL_STATUS" = "offline" ]; then
    echo "⚠️ Pool Offline | color=$COLOR_RED"
    echo "---"
    echo "Import Pool | bash=/usr/local/zfs/bin/zpool param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
    echo "Refresh | refresh=true"
    exit 0
fi

# Pool Overview Section
echo "📊 Pool Overview"
echo "--Pool: $POOL_NAME"
echo "--State: $POOL_STATUS | color=$([ "$POOL_STATUS" = "ONLINE" ] && echo "$COLOR_GREEN" || echo "$COLOR_RED")"

# Capacity details
POOL_INFO=$($ZPOOL list -H -o size,alloc,free,cap "$POOL_NAME")
SIZE=$(echo "$POOL_INFO" | awk '{print $1}')
ALLOC=$(echo "$POOL_INFO" | awk '{print $2}')
FREE=$(echo "$POOL_INFO" | awk '{print $3}')

echo "--Size: $SIZE"
echo "--Used: $ALLOC ($CAPACITY%) | color=$CAP_COLOR"
echo "--Free: $FREE | color=$COLOR_GREEN"

# Fragmentation
FRAG=$($ZPOOL list -H -o frag "$POOL_NAME")
echo "--Fragmentation: $FRAG"

# Health status
echo "---"
echo "🏥 Health Status"

# Check for errors
ERROR_COUNT=$(get_error_count)
if [ "$ERROR_COUNT" = "0" ]; then
    echo "--Errors: None $ICON_HEALTHY | color=$COLOR_GREEN"
else
    echo "--Errors: $ERROR_COUNT found $ICON_ERROR | color=$COLOR_RED"
    echo "--View Errors | bash=/usr/local/zfs/bin/zpool param1=status param2=-v param3=$POOL_NAME terminal=true"
fi

# Individual drive status
echo "---"
echo "💿 Drive Status"

DRIVE_STATUS=$($ZPOOL status "$POOL_NAME" | grep -E "disk[0-9]+.*ONLINE|disk[0-9]+.*DEGRADED|disk[0-9]+.*FAULTED")
if [ -n "$DRIVE_STATUS" ]; then
    while IFS= read -r line; do
        DISK=$(echo "$line" | awk '{print $1}')
        STATE=$(echo "$line" | awk '{print $2}')
        READ_ERR=$(echo "$line" | awk '{print $3}')
        WRITE_ERR=$(echo "$line" | awk '{print $4}')
        CKSUM_ERR=$(echo "$line" | awk '{print $5}')
        
        DISK_ICON=$(get_health_indicator "$STATE")
        DISK_COLOR=$([ "$STATE" = "ONLINE" ] && echo "$COLOR_GREEN" || echo "$COLOR_RED")
        
        echo "--$DISK_ICON $DISK: $STATE | color=$DISK_COLOR"
        
        # Show errors if any
        if [ "$READ_ERR" != "0" ] || [ "$WRITE_ERR" != "0" ] || [ "$CKSUM_ERR" != "0" ]; then
            echo "----R:$READ_ERR W:$WRITE_ERR C:$CKSUM_ERR | color=$COLOR_RED font=Monaco size=11"
        fi
    done <<< "$DRIVE_STATUS"
fi

# Dataset information
echo "---"
echo "📁 Datasets"

DATASETS=$($ZFS list -H -o name,used,avail,refer,mountpoint "$POOL_NAME" "$POOL_NAME/backups" "$POOL_NAME/data" 2>/dev/null)
if [ -n "$DATASETS" ]; then
    while IFS=$'\t' read -r name used avail refer mount; do
        # Skip the pool root in detail view
        if [ "$name" != "$POOL_NAME" ]; then
            DATASET_ICON="$ICON_DATASET"
            [ "$name" = "${POOL_NAME}/backups" ] && DATASET_ICON="$ICON_BACKUP"
            
            echo "--$DATASET_ICON $(basename "$name")"
            echo "----Used: $used"
            echo "----Available: $avail"
            echo "----Mount: $mount | font=Monaco size=10"
        fi
    done <<< "$DATASETS"
fi

# Scrub status
echo "---"
echo "$ICON_SCRUB Scrub Status"
SCRUB_STATUS=$(get_scrub_status)
echo "--$SCRUB_STATUS"

if echo "$SCRUB_STATUS" | grep -q "In Progress"; then
    echo "--Cancel Scrub | bash=/usr/local/zfs/bin/zpool param1=scrub param2=-s param3=$POOL_NAME terminal=true refresh=true"
else
    echo "--Start Scrub | bash=/usr/local/zfs/bin/zpool param1=scrub param2=$POOL_NAME terminal=true refresh=true"
fi

echo "--View Scrub History | bash=/usr/local/zfs/bin/zpool param1=history param2=$POOL_NAME terminal=true"

# Time Machine status
echo "---"
echo "$ICON_BACKUP Time Machine (Mac Mini)"
TM_STATUS=$(get_tm_status)
TM_COLOR=$(echo "$TM_STATUS" | grep -q "Active" && echo "$COLOR_GREEN" || echo "$COLOR_YELLOW")
echo "--Status: $TM_STATUS | color=$TM_COLOR"

if echo "$TM_STATUS" | grep -q "Active"; then
    echo "--Start Backup Now | bash=/usr/bin/tmutil param1=startbackup terminal=false refresh=true"
    echo "--Backup Status | bash=/usr/bin/tmutil param1=status terminal=true"
fi

# I/O Statistics
echo "---"
echo "📈 I/O Statistics"
echo "--Current Activity | bash=/usr/local/zfs/bin/zpool param1=iostat param2=$POOL_NAME param3=2 param4=5 terminal=true"
echo "--Detailed Stats | bash=/usr/local/zfs/bin/zpool param1=iostat param2=-v param3=$POOL_NAME param4=2 param5=5 terminal=true"

# Advanced options
echo "---"
echo "⚙️ Advanced"
echo "--Pool Properties | bash=/usr/local/zfs/bin/zpool param1=get param2=all param3=$POOL_NAME terminal=true"
echo "--Dataset Properties | bash=/usr/local/zfs/bin/zfs param1=get param2=all param3=$POOL_NAME terminal=true"
echo "--Pool History | bash=/usr/local/zfs/bin/zpool param1=history param2=$POOL_NAME terminal=true"
echo "--View Full Status | bash=/usr/local/zfs/bin/zpool param1=status param2=-v param3=$POOL_NAME terminal=true"

# Quick actions
echo "---"
echo "🔧 Quick Actions"
echo "--Export Pool (Unmount) | bash=/usr/local/zfs/bin/zpool param1=export param2=$POOL_NAME terminal=true refresh=true"
echo "--Import Pool | bash=/usr/local/zfs/bin/zpool param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
echo "--Clear Error Counters | bash=/usr/local/zfs/bin/zpool param1=clear param2=$POOL_NAME terminal=true refresh=true"

# Refresh option
echo "---"
echo "$ICON_REFRESH Refresh | refresh=true"

# Open in Terminal option
echo "---"
echo "🖥️ Open ZFS Terminal"
echo "--Pool Status | bash=/usr/local/zfs/bin/zpool param1=status param2=-v param3=$POOL_NAME terminal=true"
echo "--List All Pools | bash=/usr/local/zfs/bin/zpool param1=list terminal=true"
echo "--List All Datasets | bash=/usr/local/zfs/bin/zfs param1=list terminal=true"
