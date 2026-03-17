#!/bin/bash
# zfs-advanced.30s.sh — ZFS Advanced Monitor for SwiftBar
#
# SwiftBar is MIT-licensed software by Ameba Labs.
# https://github.com/swiftbar/SwiftBar — see THIRD-PARTY-LICENSES.md
#
# <xbar.title>ZFS Advanced Monitor</xbar.title>
# <xbar.version>v2.0</xbar.version>
# <xbar.author>contextinit</xbar.author>
# <xbar.author.github>contextinit</xbar.author.github>
# <xbar.desc>Advanced ZFS monitoring: ARC stats, capacity bars, trending, snapshot actions</xbar.desc>
# <xbar.dependencies>openzfs</xbar.dependencies>
# <xbar.abouturl>https://github.com/contextinit/macos-zfs-das</xbar.abouturl>
#
# <swiftbar.refreshInterval>30s</swiftbar.refreshInterval>
# <swiftbar.runInBash>false</swiftbar.runInBash>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>false</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>false</swiftbar.hideDisablePlugin>

set -uo pipefail

# ────────────────────────────────────────────────────────────
# Configuration — load from file, fall back to defaults
# ────────────────────────────────────────────────────────────
POOL_NAME="media_pool"
ZFS_BIN_PATH="/usr/local/zfs/bin"
TM_VOLUME_NAME="TimeMachine"
CAPACITY_WARNING=70
CAPACITY_CRITICAL=85
FRAG_WARNING=30
ERROR_THRESHOLD=0
TREND_CACHE_DIR="$HOME/.zfs-monitor"

for config_path in \
    "/usr/local/etc/zfs-das.conf" \
    "/etc/zfs-das.conf" \
    "$HOME/.config/zfs-das.conf"; do
    if [[ -f "$config_path" ]]; then
        # shellcheck source=/dev/null
        source "$config_path"
        break
    fi
done

ZPOOL="$ZFS_BIN_PATH/zpool"
ZFS="$ZFS_BIN_PATH/zfs"

# ────────────────────────────────────────────────────────────
# Colors — adaptive light/dark mode
# ────────────────────────────────────────────────────────────
if [[ "${OS_APPEARANCE:-Light}" == "Dark" ]]; then
    C_GREEN="#69F0AE"
    C_YELLOW="#FFD54F"
    C_RED="#FF5252"
    C_BLUE="#82B1FF"
    C_GRAY="#9E9E9E"
    C_PURPLE="#CE93D8"
else
    C_GREEN="#00796B"
    C_YELLOW="#F57F17"
    C_RED="#C62828"
    C_BLUE="#1565C0"
    C_GRAY="#616161"
    C_PURPLE="#6A1B9A"
fi

# ────────────────────────────────────────────────────────────
# SF Symbols (SwiftBar v2 sfimage= support)
# ────────────────────────────────────────────────────────────
if [[ -n "${SWIFTBAR:-}" ]]; then
    SYM_HEALTHY="checkmark.circle.fill"
    SYM_WARNING="exclamationmark.triangle.fill"
    SYM_ERROR="xmark.octagon.fill"
    SYM_OFFLINE="circle.slash"
fi

ICO_HEALTHY="🟢"
ICO_WARNING="🟡"
ICO_ERROR="🔴"
ICO_OFFLINE="⚫"
ICO_CHART="📊"
ICO_CHECK="✓"
ICO_CROSS="✗"
ICO_SCRUB="🔍"

# ────────────────────────────────────────────────────────────
# Cache directory — use a file lock to prevent race conditions
# ────────────────────────────────────────────────────────────
CACHE_DIR="${TREND_CACHE_DIR}"
mkdir -p "$CACHE_DIR"
LOCK_FILE="$CACHE_DIR/.lock"

save_metric() {
    local name="$1"
    local value="$2"
    local log="$CACHE_DIR/${name}.log"
    local tmp="$CACHE_DIR/${name}.log.tmp"
    (
        flock -n 9 || return 0
        echo "$(date +%s)|$value" >> "$log"
        tail -100 "$log" > "$tmp" && mv "$tmp" "$log"
    ) 9>"$LOCK_FILE"
}

get_trend() {
    local name="$1"
    local log="$CACHE_DIR/${name}.log"
    [[ -f "$log" ]] || { echo "→"; return; }

    local recent first last count
    recent=$(tail -5 "$log" 2>/dev/null | awk -F'|' '{print $2}')
    count=$(echo "$recent" | grep -c .)
    [[ "$count" -lt 2 ]] && { echo "→"; return; }

    first=$(echo "$recent" | head -1)
    last=$(echo  "$recent" | tail -1)

    if   [[ "$last" -gt "$first" ]]; then echo "↗"
    elif [[ "$last" -lt "$first" ]]; then echo "↘"
    else echo "→"
    fi
}

# ────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────
pool_exists() { "$ZPOOL" list "$POOL_NAME" &>/dev/null; }

get_pool_state() {
    pool_exists || { echo "OFFLINE"; return; }
    "$ZPOOL" status "$POOL_NAME" | awk '/state:/{print $2; exit}'
}

get_capacity() {
    pool_exists || { echo "0"; return; }
    "$ZPOOL" list -H -o capacity "$POOL_NAME" | tr -d '%'
}

get_fragmentation() {
    pool_exists || { echo "0"; return; }
    "$ZPOOL" list -H -o frag "$POOL_NAME" | tr -d '%'
}

state_icon() {
    case "$1" in
        ONLINE)           echo "$ICO_HEALTHY" ;;
        DEGRADED)         echo "$ICO_WARNING" ;;
        FAULTED|UNAVAIL)  echo "$ICO_ERROR"   ;;
        *)                echo "$ICO_OFFLINE" ;;
    esac
}

cap_color() {
    local c=$1
    if   [[ "$c" -lt "$CAPACITY_WARNING"  ]]; then echo "$C_GREEN"
    elif [[ "$c" -lt "$CAPACITY_CRITICAL" ]]; then echo "$C_YELLOW"
    else                                           echo "$C_RED"
    fi
}

# Unicode capacity bar (20-char wide)
capacity_bar() {
    local pct=$1
    local width=20
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done
    echo "$bar"
}

# ARC stats via macOS sysctl
get_arc_stats() {
    local arc_size arc_max arc_pct
    arc_size=$(/usr/sbin/sysctl -n kstat.zfs.misc.arcstats.size  2>/dev/null || echo "0")
    arc_max=$( /usr/sbin/sysctl -n kstat.zfs.misc.arcstats.c_max 2>/dev/null || echo "0")

    if [[ "$arc_max" -gt 0 ]]; then
        arc_pct=$(( arc_size * 100 / arc_max ))
        echo "${arc_size}|${arc_max}|${arc_pct}"
    else
        echo "0|0|0"
    fi
}

# Human-readable bytes (integer arithmetic only — no bc dependency)
format_bytes() {
    local b=$1
    if   [[ "$b" -ge 1099511627776 ]]; then echo "$(( b / 1099511627776 ))TB"
    elif [[ "$b" -ge 1073741824    ]]; then echo "$(( b / 1073741824    ))GB"
    elif [[ "$b" -ge 1048576       ]]; then echo "$(( b / 1048576       ))MB"
    else                                    echo "${b}B"
    fi
}

get_scrub_info() {
    pool_exists || { echo "never|0|"; return; }
    local line
    line=$("$ZPOOL" status "$POOL_NAME" | grep "scan:")
    if echo "$line" | grep -q "scrub in progress"; then
        local pct togo
        pct=$(echo  "$line" | grep -oE '[0-9]+\.[0-9]+%'             | head -1)
        togo=$(echo "$line" | grep -oE '[0-9]+:[0-9]+:[0-9]+ to go'  | head -1)
        echo "in_progress|${pct}|${togo}"
    elif echo "$line" | grep -q "scrub repaired"; then
        local repaired dt
        repaired=$(echo "$line" | grep -oE 'repaired [^ ]+'                          | awk '{print $2}')
        dt=$(echo        "$line" | grep -oE '[A-Z][a-z]+ [A-Z][a-z]+ +[0-9]+ [0-9:]+' | head -1)
        echo "completed|${repaired}|${dt}"
    else
        echo "never|0|"
    fi
}

get_snapshot_count() {
    pool_exists || { echo "0"; return; }
    "$ZFS" list -t snapshot -H -r "$POOL_NAME" 2>/dev/null | wc -l | tr -d ' '
}

check_encryption() {
    pool_exists || { echo "N/A"; return; }
    local enc
    enc=$("$ZFS" get -H -o value encryption "$POOL_NAME" 2>/dev/null || echo "off")
    if [[ "$enc" == "off" ]]; then
        echo "Disabled"
    else
        local ks
        ks=$("$ZFS" get -H -o value keystatus "$POOL_NAME" 2>/dev/null || echo "unknown")
        echo "AES-256 ($ks)"
    fi
}

# ────────────────────────────────────────────────────────────
# Gather data
# ────────────────────────────────────────────────────────────
STATE=$(get_pool_state)
CAPACITY=$(get_capacity)
FRAG=$(get_fragmentation)

# Pull errors from pool status output
STATUS_OUT=$("$ZPOOL" status "$POOL_NAME" 2>/dev/null || true)
POOL_LINE=$(echo "$STATUS_OUT" | awk -v p="$POOL_NAME" '$1==p {print; exit}')
R_ERR=$(echo "$POOL_LINE" | awk '{print $3+0}')
W_ERR=$(echo "$POOL_LINE" | awk '{print $4+0}')
C_ERR=$(echo "$POOL_LINE" | awk '{print $5+0}')
TOTAL_ERRORS=$(( R_ERR + W_ERR + C_ERR ))

# Save trend metrics (non-blocking via lock)
save_metric "capacity"      "$CAPACITY"
save_metric "fragmentation" "$FRAG"
save_metric "errors"        "$TOTAL_ERRORS"

# ────────────────────────────────────────────────────────────
# Determine overall health for menu bar
# ────────────────────────────────────────────────────────────
HEALTH_ICO="$ICO_HEALTHY"
HEALTH_CLR="$C_GREEN"
ALERT_TXT=""

if   [[ "$STATE" != "ONLINE" ]]; then
    HEALTH_ICO="$ICO_ERROR";   HEALTH_CLR="$C_RED";    ALERT_TXT="Pool $STATE"
elif [[ "$TOTAL_ERRORS" -gt "$ERROR_THRESHOLD" ]]; then
    HEALTH_ICO="$ICO_ERROR";   HEALTH_CLR="$C_RED";    ALERT_TXT="${TOTAL_ERRORS} Errors"
elif [[ "$CAPACITY" -ge "$CAPACITY_CRITICAL" ]]; then
    HEALTH_ICO="$ICO_WARNING"; HEALTH_CLR="$C_RED";    ALERT_TXT="${CAPACITY}% Full"
elif [[ "$CAPACITY" -ge "$CAPACITY_WARNING" || "$FRAG" -ge "$FRAG_WARNING" ]]; then
    HEALTH_ICO="$ICO_WARNING"; HEALTH_CLR="$C_YELLOW"
    [[ "$CAPACITY" -ge "$CAPACITY_WARNING" ]] && ALERT_TXT="${CAPACITY}% Used"
fi

# ────────────────────────────────────────────────────────────
# Menu bar line
# ────────────────────────────────────────────────────────────
if [[ -n "${SWIFTBAR:-}" && -n "${SYM_HEALTHY:-}" ]]; then
    case "$STATE" in
        ONLINE)   MB_SYM="$SYM_HEALTHY" ;;
        DEGRADED) MB_SYM="$SYM_WARNING" ;;
        OFFLINE)  MB_SYM="$SYM_OFFLINE" ;;
        *)        MB_SYM="$SYM_ERROR"   ;;
    esac
    if [[ -n "$ALERT_TXT" ]]; then
        echo "ZFS $ALERT_TXT | sfimage=$MB_SYM color=$HEALTH_CLR"
    else
        echo "$POOL_NAME ${CAPACITY}% | sfimage=$MB_SYM color=$HEALTH_CLR"
    fi
else
    if [[ -n "$ALERT_TXT" ]]; then
        echo "$HEALTH_ICO $ALERT_TXT | color=$HEALTH_CLR"
    else
        echo "$HEALTH_ICO $POOL_NAME ${CAPACITY}% | color=$HEALTH_CLR"
    fi
fi

echo "---"

# ────────────────────────────────────────────────────────────
# Offline shortcut
# ────────────────────────────────────────────────────────────
if [[ "$STATE" == "OFFLINE" ]]; then
    echo "Pool Not Imported | color=$C_RED size=14"
    echo "---"
    echo "Import Pool | bash=$ZPOOL param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
    echo "Refresh | refresh=true"
    exit 0
fi

# ────────────────────────────────────────────────────────────
# Status Overview
# ────────────────────────────────────────────────────────────
echo "$ICO_CHART Status Overview"
STATE_CLR=$([ "$STATE" = "ONLINE" ] && echo "$C_GREEN" || echo "$C_RED")
echo "--State: $STATE | color=$STATE_CLR"

# Capacity with trend + bar
CAP_TREND=$(get_trend "capacity")
CAP_CLR=$(cap_color "$CAPACITY")
CAP_BAR=$(capacity_bar "$CAPACITY")
echo "--Capacity: ${CAPACITY}% $CAP_TREND | color=$CAP_CLR"
echo "----$CAP_BAR | font=Menlo size=10 color=$CAP_CLR"

IFS=$'\t' read -r P_SIZE P_ALLOC P_FREE < <("$ZPOOL" list -H -o size,alloc,free "$POOL_NAME")
echo "----Total: $P_SIZE   Used: $P_ALLOC   Free: $P_FREE"

# Fragmentation with trend
FRAG_TREND=$(get_trend "fragmentation")
FRAG_CLR=$([ "$FRAG" -lt "$FRAG_WARNING" ] && echo "$C_GREEN" || echo "$C_YELLOW")
echo "--Fragmentation: ${FRAG}% $FRAG_TREND | color=$FRAG_CLR"

# Errors with trend
ERR_TREND=$(get_trend "errors")
ERR_CLR=$([ "$TOTAL_ERRORS" -eq 0 ] && echo "$C_GREEN" || echo "$C_RED")
echo "--Errors: $TOTAL_ERRORS $ERR_TREND | color=$ERR_CLR"
if [[ "$TOTAL_ERRORS" -gt 0 ]]; then
    echo "----Read: $R_ERR   Write: $W_ERR   Cksum: $C_ERR | font=Monaco size=11 color=$C_RED"
    echo "----View Details | bash=$ZPOOL param1=status param2=-v param3=$POOL_NAME terminal=true"
fi

# ────────────────────────────────────────────────────────────
# Drive Status
# ────────────────────────────────────────────────────────────
echo "---"
echo "💿 Drive Status"

while IFS= read -r line; do
    DISK=$(echo   "$line" | awk '{print $1}')
    DSTATE=$(echo "$line" | awk '{print $2}')
    DERR_R=$(echo "$line" | awk '{print $3+0}')
    DERR_W=$(echo "$line" | awk '{print $4+0}')
    DERR_C=$(echo "$line" | awk '{print $5+0}')

    DISK_ICO=$(state_icon "$DSTATE")
    DISK_CLR=$([ "$DSTATE" = "ONLINE" ] && echo "$C_GREEN" || echo "$C_RED")

    echo "--$DISK_ICO $DISK | color=$DISK_CLR"
    echo "----State: $DSTATE"
    if [[ "$DERR_R" -ne 0 || "$DERR_W" -ne 0 || "$DERR_C" -ne 0 ]]; then
        echo "----Errors: R:${DERR_R} W:${DERR_W} C:${DERR_C} | color=$C_RED"
    else
        echo "----Errors: None $ICO_CHECK | color=$C_GREEN"
    fi
done < <(echo "$STATUS_OUT" | grep -E "^\s+disk[0-9]" | sed 's/^[[:space:]]*//')

# ────────────────────────────────────────────────────────────
# Datasets & Compression
# ────────────────────────────────────────────────────────────
echo "---"
echo "📁 Datasets & Compression"

while IFS=$'\t' read -r name used avail refer comp ratio mounted; do
    [[ "$name" == "$POOL_NAME" ]] && continue
    DS_ICO="📁"
    [[ "$(basename "$name")" == "backups"    ]] && DS_ICO="💾"
    [[ "$(basename "$name")" == "data"       ]] && DS_ICO="📦"
    [[ "$(basename "$name")" == "timemachine" ]] && DS_ICO="⏱"

    MOUNT_ICO=$([ "$mounted" = "yes" ] && echo "$ICO_CHECK" || echo "$ICO_CROSS")
    echo "--$DS_ICO $(basename "$name") $MOUNT_ICO"
    echo "----Used: $used   Referenced: $refer"
    echo "----Available: $avail"
    echo "----Compression: $comp   Ratio: $ratio"
done < <("$ZFS" list -H -o name,used,avail,refer,compression,compressratio,mounted -r "$POOL_NAME" 2>/dev/null)

# ────────────────────────────────────────────────────────────
# Encryption
# ────────────────────────────────────────────────────────────
ENC_STATUS=$(check_encryption)
echo "---"
echo "🔐 Encryption"
ENC_CLR=$(echo "$ENC_STATUS" | grep -q "AES" && echo "$C_GREEN" || echo "$C_GRAY")
echo "--Status: $ENC_STATUS | color=$ENC_CLR"

# ────────────────────────────────────────────────────────────
# Snapshots
# ────────────────────────────────────────────────────────────
SNAP_COUNT=$(get_snapshot_count)
echo "---"
echo "📸 Snapshots"
echo "--Count: $SNAP_COUNT"
if [[ "$SNAP_COUNT" -gt 0 ]]; then
    echo "--List Snapshots   | bash=$ZFS param1=list param2=-t param3=snapshot param4=-r param5=$POOL_NAME terminal=true"
    echo "--Delete Oldest    | bash=$ZFS param1=destroy param2=$(\"$ZFS\" list -H -t snapshot -o name -r \"$POOL_NAME\" 2>/dev/null | head -1) terminal=true refresh=true"
fi
echo "--Create Snapshot  | bash=$ZFS param1=snapshot param2=${POOL_NAME}@manual-$(date +%Y%m%d-%H%M%S) terminal=true refresh=true"

# ────────────────────────────────────────────────────────────
# Scrub
# ────────────────────────────────────────────────────────────
echo "---"
echo "$ICO_SCRUB Scrub"

IFS='|' read -r SCRUB_STATE SCRUB_DATA SCRUB_INFO < <(get_scrub_info)

case "$SCRUB_STATE" in
    in_progress)
        echo "--$ICO_SCRUB In Progress: $SCRUB_DATA | color=$C_BLUE"
        echo "----Time remaining: $SCRUB_INFO"
        echo "--Cancel Scrub | bash=$ZPOOL param1=scrub param2=-s param3=$POOL_NAME terminal=true refresh=true"
        ;;
    completed)
        echo "--$ICO_CHECK Last: $SCRUB_INFO | color=$C_GREEN"
        echo "----Repaired: $SCRUB_DATA"
        echo "--Start New Scrub | bash=$ZPOOL param1=scrub param2=$POOL_NAME terminal=true refresh=true"
        ;;
    never)
        echo "--$ICO_WARNING Never Run | color=$C_YELLOW"
        echo "--Start Scrub | bash=$ZPOOL param1=scrub param2=$POOL_NAME terminal=true refresh=true"
        ;;
esac

# ────────────────────────────────────────────────────────────
# ARC Cache
# ────────────────────────────────────────────────────────────
echo "---"
echo "💾 ARC Cache"

IFS='|' read -r ARC_SIZE ARC_MAX ARC_PCT < <(get_arc_stats)
if [[ "$ARC_MAX" -gt 0 ]]; then
    ARC_SIZE_FMT=$(format_bytes "$ARC_SIZE")
    ARC_MAX_FMT=$(format_bytes "$ARC_MAX")
    ARC_BAR=$(capacity_bar "$ARC_PCT")
    echo "--Size: $ARC_SIZE_FMT / $ARC_MAX_FMT (${ARC_PCT}%)"
    echo "----$ARC_BAR | font=Menlo size=10 color=$C_BLUE"
else
    echo "--Info not available | color=$C_GRAY"
fi

# ────────────────────────────────────────────────────────────
# Time Machine
# ────────────────────────────────────────────────────────────
echo "---"
echo "⏱ Time Machine"

TM_VOL="${TM_VOLUME_NAME}"
if mount | grep -q "$TM_VOL"; then
    echo "--$ICO_CHECK Volume Mounted | color=$C_GREEN"

    if tmutil destinationinfo 2>/dev/null | grep -q "$TM_VOL"; then
        TM_RUNNING=$(tmutil status 2>/dev/null | grep "Running = 1" || true)
        if [[ -n "$TM_RUNNING" ]]; then
            TM_PCT=$(tmutil status 2>/dev/null | grep -oE 'Percent = [0-9.]+' | awk '{print $3}')
            echo "--$ICO_SCRUB Backup in Progress: ${TM_PCT}% | color=$C_BLUE"
            echo "--Stop Backup | bash=/usr/bin/tmutil param1=stopbackup terminal=false refresh=true"
        else
            LAST_BACKUP=$(tmutil latestbackup 2>/dev/null || true)
            [[ -n "$LAST_BACKUP" ]] && echo "--Last: $(basename "$LAST_BACKUP") | color=$C_GREEN"
            echo "--Start Backup Now | bash=/usr/bin/tmutil param1=startbackup terminal=false refresh=true"
        fi
        echo "--View Status | bash=/usr/bin/tmutil param1=status terminal=true"
    else
        echo "--$ICO_WARNING Not Configured | color=$C_YELLOW"
    fi
else
    echo "--$ICO_CROSS Not Mounted | color=$C_RED"
fi

# ────────────────────────────────────────────────────────────
# Performance
# ────────────────────────────────────────────────────────────
echo "---"
echo "📈 Performance"
echo "--Live I/O (2s × 5)  | bash=$ZPOOL param1=iostat param2=$POOL_NAME param3=2 param4=5 terminal=true"
echo "--Detailed I/O       | bash=$ZPOOL param1=iostat param2=-v param3=$POOL_NAME param4=1 param5=10 terminal=true"

# ────────────────────────────────────────────────────────────
# Quick Actions
# ────────────────────────────────────────────────────────────
echo "---"
echo "⚡ Quick Actions"
echo "--Clear Error Counters | bash=$ZPOOL param1=clear param2=$POOL_NAME terminal=true refresh=true"
echo "--Export Pool          | bash=$ZPOOL param1=export param2=$POOL_NAME terminal=true refresh=true"
echo "--Import Pool          | bash=$ZPOOL param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
echo "--Refresh              | refresh=true"

# ────────────────────────────────────────────────────────────
# Advanced / Diagnostics
# ────────────────────────────────────────────────────────────
echo "---"
echo "⚙ Advanced"
echo "--Full Pool Status   | bash=$ZPOOL param1=status param2=-v param3=$POOL_NAME terminal=true"
echo "--Pool Properties    | bash=$ZPOOL param1=get param2=all param3=$POOL_NAME terminal=true"
echo "--Dataset Properties | bash=$ZFS   param1=get param2=all param3=$POOL_NAME terminal=true"
echo "--Pool History       | bash=$ZPOOL param1=history param2=$POOL_NAME terminal=true"
echo "--View Automount Log | bash=/usr/bin/tail param1=-100 param2=/var/log/zfs-automount.log terminal=true"

# ────────────────────────────────────────────────────────────
# About
# ────────────────────────────────────────────────────────────
echo "---"
echo "ℹ About"
ZFS_VERSION=$("$ZPOOL" version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
echo "--ZFS: $ZFS_VERSION"
echo "--Pool: $POOL_NAME"
echo "--Refresh: every 30s"
echo "--macos-zfs-das | href=https://github.com/contextinit/macos-zfs-das"
