#!/bin/bash

# <xbar.title>ZFS Advanced Monitor</xbar.title>
# <xbar.version>v2.0</xbar.version>
# <xbar.author>Your Name</xbar.author>
# <xbar.desc>Advanced ZFS monitoring with alerts, graphs, and detailed metrics</xbar.desc>
# <xbar.dependencies>openzfs</xbar.dependencies>

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

# Configuration with fallback defaults
if [ "$CONFIG_LOADED" = false ]; then
    POOL_NAME="media_pool"
    ZFS_BIN_PATH="/usr/local/zfs/bin"
    CAPACITY_WARNING=70
    CAPACITY_CRITICAL=85
    ERROR_THRESHOLD=10
    FRAG_WARNING=30
    TREND_CACHE_DIR="$HOME/.zfs-monitor"
fi

ZPOOL="$ZFS_BIN_PATH/zpool"
ZFS="$ZFS_BIN_PATH/zfs"

# Colors
COLOR_GREEN="#00C853"
COLOR_YELLOW="#FFB300"
COLOR_RED="#D50000"
COLOR_BLUE="#2979FF"
COLOR_GRAY="#616161"
COLOR_PURPLE="#9C27B0"

# SF Symbols / Emoji
ICON_HEALTHY="🟢"
ICON_WARNING="🟡"
ICON_ERROR="🔴"
ICON_OFFLINE="⚫"
ICON_CHART="📊"
ICON_ALERT="⚠️"
ICON_CHECK="✓"
ICON_CROSS="✗"

# Cache directory for historical data
CACHE_DIR="${TREND_CACHE_DIR:-$HOME/.zfs-monitor}"
mkdir -p "$CACHE_DIR"

# Functions
check_pool_exists() {
    $ZPOOL list "$POOL_NAME" &>/dev/null
}

get_pool_state() {
    if ! check_pool_exists; then
        echo "OFFLINE"
        return
    fi
    $ZPOOL status "$POOL_NAME" | grep "state:" | awk '{print $2}'
}

get_pool_capacity() {
    if ! check_pool_exists; then
        echo "0"
        return
    fi
    $ZPOOL list -H -o capacity "$POOL_NAME" | tr -d '%'
}

get_pool_size_info() {
    if ! check_pool_exists; then
        echo "0|0|0"
        return
    fi
    $ZPOOL list -H -o size,alloc,free "$POOL_NAME" | tr '\t' '|'
}

get_fragmentation() {
    if ! check_pool_exists; then
        echo "0"
        return
    fi
    $ZPOOL list -H -o frag "$POOL_NAME" | tr -d '%'
}

get_error_counts() {
    if ! check_pool_exists; then
        echo "0|0|0"
        return
    fi
    
    local status=$($ZPOOL status "$POOL_NAME")
    local read_err=$(echo "$status" | grep "errors:" | head -1 | grep -oE '[0-9]+' | head -1)
    local write_err=$(echo "$status" | grep "errors:" | sed -n '2p' | grep -oE '[0-9]+' | head -1)
    local cksum_err=$(echo "$status" | grep "errors:" | sed -n '3p' | grep -oE '[0-9]+' | head -1)
    
    # Default to 0 if grep returns nothing
    read_err=${read_err:-0}
    write_err=${write_err:-0}
    cksum_err=${cksum_err:-0}
    
    echo "${read_err}|${write_err}|${cksum_err}"
}

get_scrub_info() {
    if ! check_pool_exists; then
        echo "never|0|0"
        return
    fi
    
    local scrub_line=$($ZPOOL status "$POOL_NAME" | grep "scan:")
    
    if echo "$scrub_line" | grep -q "scrub in progress"; then
        local percent=$(echo "$scrub_line" | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local to_go=$(echo "$scrub_line" | grep -oE '[0-9]+:[0-9]+:[0-9]+ to go')
        echo "in_progress|${percent}|${to_go}"
    elif echo "$scrub_line" | grep -q "scrub repaired"; then
        local repaired=$(echo "$scrub_line" | grep -oE 'repaired [^ ]+' | awk '{print $2}')
        local date=$(echo "$scrub_line" | grep -oE '[A-Z][a-z]+ [A-Z][a-z]+ [0-9]+ [0-9]+:[0-9]+:[0-9]+ [0-9]+')
        echo "completed|${repaired}|${date}"
    else
        echo "never|0|0"
    fi
}

get_dataset_info() {
    if ! check_pool_exists; then
        return
    fi
    $ZFS list -H -o name,used,avail,refer,compression,compressratio,mounted 2>/dev/null
}

get_snapshot_count() {
    if ! check_pool_exists; then
        echo "0"
        return
    fi
    $ZFS list -t snapshot -H 2>/dev/null | wc -l | tr -d ' '
}

check_encryption_status() {
    if ! check_pool_exists; then
        echo "N/A"
        return
    fi
    
    local enc_status=$($ZFS get -H -o value encryption "$POOL_NAME/backups" 2>/dev/null)
    if [ "$enc_status" = "off" ]; then
        echo "Not Encrypted"
    else
        local key_status=$($ZFS get -H -o value keystatus "$POOL_NAME/backups" 2>/dev/null)
        echo "Encrypted ($key_status)"
    fi
}

get_arc_stats() {
    if [ -f "/proc/spl/kstat/zfs/arcstats" ]; then
        # Linux style
        local arc_size=$(grep "^size" /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
        local arc_max=$(grep "^c_max" /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
    else
        # macOS - use sysctl if available
        local arc_size=$(/usr/sbin/sysctl -n kstat.zfs.misc.arcstats.size 2>/dev/null || echo "0")
        local arc_max=$(/usr/sbin/sysctl -n kstat.zfs.misc.arcstats.c_max 2>/dev/null || echo "0")
    fi
    
    if [ "$arc_max" -gt 0 ]; then
        local arc_pct=$((arc_size * 100 / arc_max))
        echo "${arc_size}|${arc_max}|${arc_pct}"
    else
        echo "0|0|0"
    fi
}

format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1099511627776 ]; then
        echo "$(echo "scale=2; $bytes / 1099511627776" | bc)TB"
    elif [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc)MB"
    else
        echo "${bytes}B"
    fi
}

create_capacity_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    echo "$bar"
}

save_metric() {
    local metric_name=$1
    local value=$2
    echo "$(date +%s)|$value" >> "$CACHE_DIR/${metric_name}.log"
    
    # Keep only last 100 entries
    tail -100 "$CACHE_DIR/${metric_name}.log" > "$CACHE_DIR/${metric_name}.log.tmp"
    mv "$CACHE_DIR/${metric_name}.log.tmp" "$CACHE_DIR/${metric_name}.log"
}

get_trend() {
    local metric_name=$1
    
    if [ ! -f "$CACHE_DIR/${metric_name}.log" ]; then
        echo "→"
        return
    fi
    
    local recent=$(tail -5 "$CACHE_DIR/${metric_name}.log" | awk -F'|' '{print $2}')
    local count=$(echo "$recent" | wc -l)
    
    if [ "$count" -lt 2 ]; then
        echo "→"
        return
    fi
    
    local first=$(echo "$recent" | head -1)
    local last=$(echo "$recent" | tail -1)
    
    if [ "$last" -gt "$first" ]; then
        echo "↗"
    elif [ "$last" -lt "$first" ]; then
        echo "↘"
    else
        echo "→"
    fi
}

# Main execution
STATE=$(get_pool_state)
CAPACITY=$(get_pool_capacity)
FRAG=$(get_fragmentation)
IFS='|' read -r READ_ERR WRITE_ERR CKSUM_ERR <<< "$(get_error_counts)"
TOTAL_ERRORS=$((READ_ERR + WRITE_ERR + CKSUM_ERR))

# Save metrics for trending
save_metric "capacity" "$CAPACITY"
save_metric "fragmentation" "$FRAG"
save_metric "errors" "$TOTAL_ERRORS"

# Determine overall health
HEALTH_ICON="$ICON_HEALTHY"
HEALTH_COLOR="$COLOR_GREEN"
ALERT_TEXT=""

if [ "$STATE" != "ONLINE" ]; then
    HEALTH_ICON="$ICON_ERROR"
    HEALTH_COLOR="$COLOR_RED"
    ALERT_TEXT="Pool $STATE"
elif [ "$TOTAL_ERRORS" -gt "$ERROR_THRESHOLD" ]; then
    HEALTH_ICON="$ICON_ERROR"
    HEALTH_COLOR="$COLOR_RED"
    ALERT_TEXT="$TOTAL_ERRORS Errors"
elif [ "$CAPACITY" -ge "$CAPACITY_CRITICAL" ]; then
    HEALTH_ICON="$ICON_WARNING"
    HEALTH_COLOR="$COLOR_RED"
    ALERT_TEXT="${CAPACITY}% Full"
elif [ "$CAPACITY" -ge "$CAPACITY_WARNING" ] || [ "$FRAG" -ge "$FRAG_WARNING" ]; then
    HEALTH_ICON="$ICON_WARNING"
    HEALTH_COLOR="$COLOR_YELLOW"
    [ "$CAPACITY" -ge "$CAPACITY_WARNING" ] && ALERT_TEXT="${CAPACITY}% Used"
fi

# Menu bar display
if [ -n "$ALERT_TEXT" ]; then
    echo "$HEALTH_ICON $ALERT_TEXT | color=$HEALTH_COLOR"
else
    echo "$HEALTH_ICON $POOL_NAME ${CAPACITY}% | color=$HEALTH_COLOR"
fi

echo "---"

# Check if pool is offline
if [ "$STATE" = "OFFLINE" ]; then
    echo "❌ Pool Not Imported | color=$COLOR_RED size=14"
    echo "---"
    echo "Import Pool | bash=$ZPOOL param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
    echo "Refresh | refresh=true"
    exit 0
fi

# ===== STATUS OVERVIEW =====
echo "📊 Status Overview"
echo "--State: $STATE | color=$([ "$STATE" = "ONLINE" ] && echo "$COLOR_GREEN" || echo "$COLOR_RED")"

# Capacity with trend
CAP_TREND=$(get_trend "capacity")
CAP_BAR=$(create_capacity_bar "$CAPACITY")
CAP_COLOR=$([ "$CAPACITY" -lt "$CAPACITY_WARNING" ] && echo "$COLOR_GREEN" || [ "$CAPACITY" -lt "$CAPACITY_CRITICAL" ] && echo "$COLOR_YELLOW" || echo "$COLOR_RED")
echo "--Capacity: ${CAPACITY}% $CAP_TREND | color=$CAP_COLOR"
echo "----$CAP_BAR | font=Menlo size=10"

IFS='|' read -r SIZE ALLOC FREE <<< "$(get_pool_size_info)"
echo "----Size: $SIZE | Total: $ALLOC used, $FREE free"

# Fragmentation with trend
FRAG_TREND=$(get_trend "fragmentation")
FRAG_COLOR=$([ "$FRAG" -lt "$FRAG_WARNING" ] && echo "$COLOR_GREEN" || echo "$COLOR_YELLOW")
echo "--Fragmentation: ${FRAG}% $FRAG_TREND | color=$FRAG_COLOR"

# Errors with trend
ERR_TREND=$(get_trend "errors")
ERR_COLOR=$([ "$TOTAL_ERRORS" -eq 0 ] && echo "$COLOR_GREEN" || echo "$COLOR_RED")
echo "--Errors: $TOTAL_ERRORS $ERR_TREND | color=$ERR_COLOR"
if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo "----Read: $READ_ERR, Write: $WRITE_ERR, Checksum: $CKSUM_ERR | font=Monaco size=11"
    echo "----View Details | bash=$ZPOOL param1=status param2=-v param3=$POOL_NAME terminal=true"
fi

# ===== DRIVE STATUS =====
echo "---"
echo "💿 Drive Status (RAIDZ1)"

DRIVE_INFO=$($ZPOOL status "$POOL_NAME" | grep -A 20 "raidz1-0")
echo "$DRIVE_INFO" | grep "disk[0-9]" | while read -r line; do
    DISK=$(echo "$line" | awk '{print $1}')
    DSTATE=$(echo "$line" | awk '{print $2}')
    DREAD=$(echo "$line" | awk '{print $3}')
    DWRITE=$(echo "$line" | awk '{print $4}')
    DCKSUM=$(echo "$line" | awk '{print $5}')
    
    DISK_ICON=$([ "$DSTATE" = "ONLINE" ] && echo "$ICON_HEALTHY" || echo "$ICON_ERROR")
    DISK_COLOR=$([ "$DSTATE" = "ONLINE" ] && echo "$COLOR_GREEN" || echo "$COLOR_RED")
    
    echo "--$DISK_ICON $DISK | color=$DISK_COLOR"
    echo "----State: $DSTATE"
    
    if [ "$DREAD" != "0" ] || [ "$DWRITE" != "0" ] || [ "$DCKSUM" != "0" ]; then
        echo "----Errors: R:$DREAD W:$DWRITE C:$DCKSUM | color=$COLOR_RED"
    else
        echo "----Errors: None $ICON_CHECK | color=$COLOR_GREEN"
    fi
done

# ===== DATASETS =====
echo "---"
echo "📁 Datasets & Compression"

get_dataset_info | while IFS=$'\t' read -r name used avail refer comp ratio mounted; do
    if [ "$name" != "$POOL_NAME" ]; then
        DS_ICON="📁"
        [ "$(basename "$name")" = "backups" ] && DS_ICON="💾"
        [ "$(basename "$name")" = "data" ] && DS_ICON="📦"
        
        MOUNT_ICON=$([ "$mounted" = "yes" ] && echo "$ICON_CHECK" || echo "$ICON_CROSS")
        
        echo "--$DS_ICON $(basename "$name") $MOUNT_ICON"
        echo "----Used: $used (Referenced: $refer)"
        echo "----Available: $avail"
        echo "----Compression: $comp (Ratio: $ratio)"
    fi
done

# Encryption status
ENC_STATUS=$(check_encryption_status)
echo "---"
echo "🔐 Encryption"
echo "--Status: $ENC_STATUS"

# Snapshot count
SNAP_COUNT=$(get_snapshot_count)
echo "---"
echo "📸 Snapshots"
echo "--Count: $SNAP_COUNT"
if [ "$SNAP_COUNT" -gt 0 ]; then
    echo "--List Snapshots | bash=$ZFS param1=list param2=-t param3=snapshot terminal=true"
fi

# ===== SCRUB STATUS =====
echo "---"
echo "🔍 Scrub Status"

IFS='|' read -r SCRUB_STATE SCRUB_DATA SCRUB_INFO <<< "$(get_scrub_info)"

case "$SCRUB_STATE" in
    "in_progress")
        echo "--$ICON_SCRUB In Progress: ${SCRUB_DATA}% | color=$COLOR_BLUE"
        echo "----Time remaining: $SCRUB_INFO"
        echo "--Cancel Scrub | bash=$ZPOOL param1=scrub param2=-s param3=$POOL_NAME terminal=true refresh=true"
        ;;
    "completed")
        echo "--$ICON_CHECK Last Completed: $SCRUB_INFO | color=$COLOR_GREEN"
        echo "----Repaired: $SCRUB_DATA"
        echo "--Start New Scrub | bash=$ZPOOL param1=scrub param2=$POOL_NAME terminal=true refresh=true"
        ;;
    "never")
        echo "--$ICON_WARNING Never Run | color=$COLOR_YELLOW"
        echo "--Start Scrub | bash=$ZPOOL param1=scrub param2=$POOL_NAME terminal=true refresh=true"
        ;;
esac

# ===== ARC STATS =====
echo "---"
echo "💾 ARC Cache"

IFS='|' read -r ARC_SIZE ARC_MAX ARC_PCT <<< "$(get_arc_stats)"
if [ "$ARC_MAX" -gt 0 ]; then
    ARC_SIZE_FMT=$(format_bytes "$ARC_SIZE")
    ARC_MAX_FMT=$(format_bytes "$ARC_MAX")
    echo "--Size: $ARC_SIZE_FMT / $ARC_MAX_FMT (${ARC_PCT}%)"
    ARC_BAR=$(create_capacity_bar "$ARC_PCT")
    echo "----$ARC_BAR | font=Menlo size=10"
else
    echo "--Info not available"
fi

# ===== TIME MACHINE =====
echo "---"
echo "⏱️ Time Machine"

TM_VOL="${TM_VOLUME_NAME:-RMMacMM4}"
if mount | grep -q "$TM_VOL"; then
    echo "--$ICON_CHECK Backup Volume Mounted | color=$COLOR_GREEN"
    
    if tmutil destinationinfo 2>/dev/null | grep -q "$TM_VOL"; then
        TM_RUNNING=$(tmutil status 2>/dev/null | grep "Running = 1")
        
        if [ -n "$TM_RUNNING" ]; then
            TM_PERCENT=$(tmutil status 2>/dev/null | grep "Percent" | grep -oE '[0-9]+\.[0-9]+' | head -1)
            echo "--$ICON_SCRUB Backup in Progress: ${TM_PERCENT}% | color=$COLOR_BLUE"
            echo "--Stop Backup | bash=/usr/bin/tmutil param1=stopbackup terminal=false refresh=true"
        else
            LAST_BACKUP=$(tmutil latestbackup 2>/dev/null)
            if [ -n "$LAST_BACKUP" ]; then
                BACKUP_DATE=$(basename "$LAST_BACKUP")
                echo "--Last Backup: $BACKUP_DATE | color=$COLOR_GREEN"
            fi
            echo "--Start Backup | bash=/usr/bin/tmutil param1=startbackup terminal=false refresh=true"
        fi
        
        echo "--View Status | bash=/usr/bin/tmutil param1=status terminal=true"
    else
        echo "--$ICON_WARNING Not Configured | color=$COLOR_YELLOW"
    fi
else
    echo "--$ICON_CROSS Not Mounted | color=$COLOR_RED"
fi

# ===== PERFORMANCE =====
echo "---"
echo "📈 Performance"
echo "--Current I/O Stats | bash=$ZPOOL param1=iostat param2=$POOL_NAME param3=2 param4=5 terminal=true"
echo "--Detailed I/O | bash=$ZPOOL param1=iostat param2=-v param3=$POOL_NAME param4=1 param5=10 terminal=true"

# ===== QUICK ACTIONS =====
echo "---"
echo "⚡ Quick Actions"
echo "--Clear Error Counters | bash=$ZPOOL param1=clear param2=$POOL_NAME terminal=true refresh=true"
echo "--Refresh Display | refresh=true"
echo "---"
echo "--Export Pool | bash=$ZPOOL param1=export param2=$POOL_NAME terminal=true refresh=true"
echo "--Import Pool | bash=$ZPOOL param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"

# ===== ADVANCED =====
echo "---"
echo "⚙️ Advanced"
echo "--Full Pool Status | bash=$ZPOOL param1=status param2=-v param3=$POOL_NAME terminal=true"
echo "--Pool Properties | bash=$ZPOOL param1=get param2=all param3=$POOL_NAME terminal=true"
echo "--Dataset Properties | bash=$ZFS param1=get param2=all param3=$POOL_NAME/backups terminal=true"
echo "--Pool History | bash=$ZPOOL param1=history param2=$POOL_NAME terminal=true"
echo "--View Logs | bash=tail param1=-100 param2=/var/log/zfs-automount.log terminal=true"

# ===== ABOUT =====
echo "---"
echo "ℹ️ About"
echo "--ZFS Version: $(zpool version | head -1 | awk '{print $2}')"
echo "--Pool: $POOL_NAME"
echo "--Monitoring: Active"
echo "--Refresh: Every 30s"
