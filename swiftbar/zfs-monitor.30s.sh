#!/bin/bash
# zfs-monitor.30s.sh — ZFS Pool Monitor for SwiftBar
#
# SwiftBar is MIT-licensed software by Ameba Labs.
# https://github.com/swiftbar/SwiftBar — see THIRD-PARTY-LICENSES.md
#
# <xbar.title>ZFS Pool Monitor</xbar.title>
# <xbar.version>v2.0</xbar.version>
# <xbar.author>contextinit</xbar.author>
# <xbar.author.github>contextinit</xbar.author.github>
# <xbar.desc>Monitors ZFS pool health, capacity, and status on macOS</xbar.desc>
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
# Colors — adaptive light/dark mode via OS_APPEARANCE env var
# (SwiftBar sets OS_APPEARANCE to "Dark" or "Light")
# ────────────────────────────────────────────────────────────
if [[ "${OS_APPEARANCE:-Light}" == "Dark" ]]; then
    C_GREEN="#69F0AE"
    C_YELLOW="#FFD54F"
    C_RED="#FF5252"
    C_BLUE="#82B1FF"
    C_GRAY="#9E9E9E"
else
    C_GREEN="#00796B"
    C_YELLOW="#F57F17"
    C_RED="#C62828"
    C_BLUE="#1565C0"
    C_GRAY="#616161"
fi

# ────────────────────────────────────────────────────────────
# SF Symbols (macOS 11+, graceful emoji fallback)
# ────────────────────────────────────────────────────────────
if [[ -n "${SWIFTBAR:-}" ]]; then
    # SwiftBar supports sfimage= natively; use named symbols as menu bar icon
    SYM_HEALTHY="checkmark.circle.fill"
    SYM_WARNING="exclamationmark.triangle.fill"
    SYM_ERROR="xmark.octagon.fill"
    SYM_OFFLINE="circle.slash"
fi

ICO_HEALTHY="🟢"
ICO_WARNING="🟡"
ICO_ERROR="🔴"
ICO_OFFLINE="⚫"
ICO_DRIVE="💿"
ICO_DATASET="📁"
ICO_BACKUP="⏱"
ICO_SCRUB="🔍"
ICO_REFRESH="🔄"

# ────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────
pool_exists() {
    "$ZPOOL" list "$POOL_NAME" &>/dev/null
}

get_pool_state() {
    if ! pool_exists; then
        echo "OFFLINE"
        return
    fi
    "$ZPOOL" status "$POOL_NAME" | awk '/state:/{print $2; exit}'
}

get_capacity() {
    if ! pool_exists; then
        echo "0"
        return
    fi
    "$ZPOOL" list -H -o capacity "$POOL_NAME" | tr -d '%'
}

cap_color() {
    local cap=$1
    if   [[ "$cap" -lt 70 ]]; then echo "$C_GREEN"
    elif [[ "$cap" -lt 85 ]]; then echo "$C_YELLOW"
    else                            echo "$C_RED"
    fi
}

state_icon() {
    case "$1" in
        ONLINE)           echo "$ICO_HEALTHY" ;;
        DEGRADED)         echo "$ICO_WARNING" ;;
        FAULTED|UNAVAIL)  echo "$ICO_ERROR"   ;;
        OFFLINE)          echo "$ICO_OFFLINE" ;;
        *)                echo "❓"           ;;
    esac
}

get_scrub_status() {
    if ! pool_exists; then echo "Pool offline"; return; fi
    local line
    line=$("$ZPOOL" status "$POOL_NAME" | grep "scan:")
    if echo "$line" | grep -q "scrub in progress"; then
        local pct
        pct=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+%' | head -1)
        echo "In Progress: $pct"
    elif echo "$line" | grep -q "scrub repaired"; then
        local dt
        dt=$(echo "$line" | grep -oE '[A-Z][a-z]+ [A-Z][a-z]+ +[0-9]+ [0-9:]+' | head -1)
        echo "Last: $dt"
    elif echo "$line" | grep -q "none requested"; then
        echo "Never run"
    else
        echo "Unknown"
    fi
}

get_tm_status() {
    local vol="${TM_VOLUME_NAME}"
    if mount | grep -q "$vol"; then
        if tmutil destinationinfo 2>/dev/null | grep -q "$vol"; then
            local last
            last=$(tmutil latestbackup 2>/dev/null)
            if [[ -n "$last" ]]; then
                echo "Active (Last: $(basename "$last" | cut -d'-' -f1-3))"
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

# ────────────────────────────────────────────────────────────
# Gather data
# ────────────────────────────────────────────────────────────
STATE=$(get_pool_state)
CAPACITY=$(get_capacity)
CAP_COLOR=$(cap_color "$CAPACITY")
STATE_ICO=$(state_icon "$STATE")

# ────────────────────────────────────────────────────────────
# Menu bar line
# ────────────────────────────────────────────────────────────
if [[ -n "${SWIFTBAR:-}" && -n "${SYM_HEALTHY:-}" ]]; then
    case "$STATE" in
        ONLINE)   MENUBAR_SYM="$SYM_HEALTHY" ;;
        DEGRADED) MENUBAR_SYM="$SYM_WARNING" ;;
        OFFLINE)  MENUBAR_SYM="$SYM_OFFLINE" ;;
        *)        MENUBAR_SYM="$SYM_ERROR"   ;;
    esac
    echo "$POOL_NAME ${CAPACITY}% | sfimage=$MENUBAR_SYM color=$CAP_COLOR"
else
    echo "$STATE_ICO $POOL_NAME ${CAPACITY}% | color=$CAP_COLOR"
fi

echo "---"

# ────────────────────────────────────────────────────────────
# Offline shortcut
# ────────────────────────────────────────────────────────────
if [[ "$STATE" == "OFFLINE" ]]; then
    echo "⚠ Pool Not Imported | color=$C_RED"
    echo "---"
    echo "Import Pool | bash=$ZPOOL param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
    echo "$ICO_REFRESH Refresh | refresh=true"
    exit 0
fi

# ────────────────────────────────────────────────────────────
# Pool Overview
# ────────────────────────────────────────────────────────────
echo "📊 Pool Overview"
echo "--Pool: $POOL_NAME"

STATE_COLOR=$([ "$STATE" = "ONLINE" ] && echo "$C_GREEN" || echo "$C_RED")
echo "--State: $STATE | color=$STATE_COLOR"

POOL_INFO=$("$ZPOOL" list -H -o size,alloc,free,frag "$POOL_NAME")
P_SIZE=$(echo  "$POOL_INFO" | awk '{print $1}')
P_ALLOC=$(echo "$POOL_INFO" | awk '{print $2}')
P_FREE=$(echo  "$POOL_INFO" | awk '{print $3}')
P_FRAG=$(echo  "$POOL_INFO" | awk '{print $4}')

echo "--Size: $P_SIZE"
echo "--Used: $P_ALLOC (${CAPACITY}%) | color=$CAP_COLOR"
echo "--Free: $P_FREE | color=$C_GREEN"
echo "--Fragmentation: $P_FRAG"

# ────────────────────────────────────────────────────────────
# Health / Errors
# ────────────────────────────────────────────────────────────
echo "---"
echo "🏥 Health"

STATUS_OUT=$("$ZPOOL" status "$POOL_NAME" 2>/dev/null)
POOL_LINE=$(echo "$STATUS_OUT" | awk -v pool="$POOL_NAME" '$1==pool {print}' | head -1)
R_ERR=$(echo "$POOL_LINE" | awk '{print $3}')
W_ERR=$(echo "$POOL_LINE" | awk '{print $4}')
C_ERR=$(echo "$POOL_LINE" | awk '{print $5}')
TOTAL_ERR=$(( ${R_ERR:-0} + ${W_ERR:-0} + ${C_ERR:-0} ))

if [[ "$TOTAL_ERR" -eq 0 ]]; then
    echo "--Errors: None $ICO_HEALTHY | color=$C_GREEN"
else
    echo "--Errors: $TOTAL_ERR found $ICO_ERROR | color=$C_RED"
    echo "--Read: ${R_ERR}  Write: ${W_ERR}  Cksum: ${C_ERR} | font=Monaco size=11 color=$C_RED"
    echo "--View Error Detail | bash=$ZPOOL param1=status param2=-v param3=$POOL_NAME terminal=true"
fi

# ────────────────────────────────────────────────────────────
# Drive Status
# ────────────────────────────────────────────────────────────
echo "---"
echo "$ICO_DRIVE Drive Status"

while IFS= read -r line; do
    DISK=$(echo  "$line" | awk '{print $1}')
    DSTATE=$(echo "$line" | awk '{print $2}')
    DERR_R=$(echo "$line" | awk '{print $3}')
    DERR_W=$(echo "$line" | awk '{print $4}')
    DERR_C=$(echo "$line" | awk '{print $5}')

    DISK_ICO=$(state_icon "$DSTATE")
    DISK_CLR=$([ "$DSTATE" = "ONLINE" ] && echo "$C_GREEN" || echo "$C_RED")

    echo "--$DISK_ICO $DISK: $DSTATE | color=$DISK_CLR"
    if [[ "${DERR_R:-0}" != "0" || "${DERR_W:-0}" != "0" || "${DERR_C:-0}" != "0" ]]; then
        echo "----R:${DERR_R} W:${DERR_W} C:${DERR_C} | color=$C_RED font=Monaco size=11"
    fi
done < <(echo "$STATUS_OUT" | grep -E "^\s+disk[0-9]" | sed 's/^[[:space:]]*//')

# ────────────────────────────────────────────────────────────
# Datasets
# ────────────────────────────────────────────────────────────
echo "---"
echo "$ICO_DATASET Datasets"

while IFS=$'\t' read -r name used avail refer mount; do
    [[ "$name" == "$POOL_NAME" ]] && continue
    DS_ICO="$ICO_DATASET"
    [[ "$(basename "$name")" == "backups" || "$(basename "$name")" == "timemachine" ]] && DS_ICO="$ICO_BACKUP"

    echo "--$DS_ICO $(basename "$name")"
    echo "----Used: $used   Available: $avail"
    echo "----Mount: $mount | font=Monaco size=10"
done < <("$ZFS" list -H -o name,used,avail,refer,mountpoint -r "$POOL_NAME" 2>/dev/null)

# ────────────────────────────────────────────────────────────
# Scrub
# ────────────────────────────────────────────────────────────
echo "---"
echo "$ICO_SCRUB Scrub"
SCRUB=$(get_scrub_status)
echo "--$SCRUB"

if echo "$SCRUB" | grep -q "In Progress"; then
    echo "--Cancel Scrub | bash=$ZPOOL param1=scrub param2=-s param3=$POOL_NAME terminal=true refresh=true"
else
    echo "--Start Scrub | bash=$ZPOOL param1=scrub param2=$POOL_NAME terminal=true refresh=true"
fi

# ────────────────────────────────────────────────────────────
# Time Machine
# ────────────────────────────────────────────────────────────
echo "---"
echo "$ICO_BACKUP Time Machine"
TM=$(get_tm_status)
TM_CLR=$(echo "$TM" | grep -q "Active" && echo "$C_GREEN" || echo "$C_YELLOW")
echo "--Status: $TM | color=$TM_CLR"

if echo "$TM" | grep -q "Active"; then
    echo "--Start Backup Now | bash=/usr/bin/tmutil param1=startbackup terminal=false refresh=true"
    echo "--Backup Status    | bash=/usr/bin/tmutil param1=status terminal=true"
fi

# ────────────────────────────────────────────────────────────
# I/O Stats
# ────────────────────────────────────────────────────────────
echo "---"
echo "📈 I/O Stats"
echo "--Current Activity | bash=$ZPOOL param1=iostat param2=$POOL_NAME param3=2 param4=5 terminal=true"
echo "--Detailed Stats   | bash=$ZPOOL param1=iostat param2=-v param3=$POOL_NAME param4=2 param5=5 terminal=true"

# ────────────────────────────────────────────────────────────
# Quick Actions
# ────────────────────────────────────────────────────────────
echo "---"
echo "⚡ Quick Actions"
echo "--Export Pool (Unmount) | bash=$ZPOOL param1=export param2=$POOL_NAME terminal=true refresh=true"
echo "--Import Pool           | bash=$ZPOOL param1=import param2=-d param3=/dev param4=$POOL_NAME terminal=true refresh=true"
echo "--Clear Error Counters  | bash=$ZPOOL param1=clear param2=$POOL_NAME terminal=true refresh=true"
echo "--Full Pool Status      | bash=$ZPOOL param1=status param2=-v param3=$POOL_NAME terminal=true"
echo "--List All Datasets     | bash=$ZFS   param1=list terminal=true"

# ────────────────────────────────────────────────────────────
# Refresh
# ────────────────────────────────────────────────────────────
echo "---"
echo "$ICO_REFRESH Refresh | refresh=true"
