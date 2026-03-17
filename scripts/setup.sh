#!/bin/bash
# setup.sh — macOS ZFS DAS Interactive Onboarding Installer
#
# Guides you through a complete ZFS DAS setup in phases:
#   1 → Legal disclaimer & acceptance
#   2 → System compatibility checks
#   3 → Drive identification & survey
#   4 → Disk preparation commands (TEXT ONLY — you run them manually)
#   5 → Pool configuration wizard
#   6 → Optional features (encryption, Time Machine, monitoring, auto-mount)
#   7 → Full review & final confirmation
#   8 → Automated installation
#   9 → Completion summary
#
# Usage: sudo bash scripts/setup.sh
#
# Author: macOS ZFS DAS Project — https://github.com/contextinit/macos-zfs-das
# License: MIT

# ══════════════════════════════════════════════════════════════════════════════
# Bootstrap — no set -e yet; we handle errors ourselves during the wizard
# ══════════════════════════════════════════════════════════════════════════════
export LC_ALL=C
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# ══════════════════════════════════════════════════════════════════════════════
# Terminal colours & glyphs
# ══════════════════════════════════════════════════════════════════════════════
if [[ -t 1 ]]; then
    BOLD=$'\033[1m';    DIM=$'\033[2m';     RESET=$'\033[0m'
    RED=$'\033[0;31m';  BRED=$'\033[1;31m'
    GRN=$'\033[0;32m';  BGRN=$'\033[1;32m'
    YLW=$'\033[0;33m';  BYLO=$'\033[1;33m'
    BLU=$'\033[0;34m';  BBLU=$'\033[1;34m'
    CYN=$'\033[0;36m';  BCYN=$'\033[1;36m'
    WHT=$'\033[1;37m'
else
    BOLD=''; DIM=''; RESET=''; RED=''; BRED=''; GRN=''; BGRN=''
    YLW=''; BYLO=''; BLU=''; BBLU=''; CYN=''; BCYN=''; WHT=''
fi

SYM_OK="${BGRN}✓${RESET}"
SYM_WARN="${BYLO}⚠${RESET}"
SYM_FAIL="${BRED}✗${RESET}"
SYM_INFO="${BBLU}ℹ${RESET}"
SYM_ARROW="${CYN}→${RESET}"

# ══════════════════════════════════════════════════════════════════════════════
# UI helpers
# ══════════════════════════════════════════════════════════════════════════════
TERM_WIDTH=78

# Full-width horizontal rule
hr() { printf '%*s\n' "$TERM_WIDTH" '' | tr ' ' "${1:-─}"; }

# Phase banner  e.g.  banner "═" "  PHASE 1 OF 9 — LEGAL DISCLAIMER  "
banner() {
    local char="$1"; local text="$2"
    local pad=$(( (TERM_WIDTH - ${#text}) / 2 ))
    hr "$char"
    printf "%${pad}s%s\n" '' "${BBLU}${BOLD}${text}${RESET}"
    hr "$char"
    echo
}

phase_header() {
    local num="$1"; local total="$2"; local title="$3"
    echo
    hr "═"
    printf "  ${BBLU}${BOLD}PHASE %s of %s${RESET}  —  ${WHT}${BOLD}%s${RESET}\n" \
        "$num" "$total" "$title"
    hr "═"
    echo
}

ok()   { echo "  ${SYM_OK}  $*"; }
warn() { echo "  ${SYM_WARN}  ${BYLO}$*${RESET}"; }
fail() { echo "  ${SYM_FAIL}  ${BRED}$*${RESET}"; }
info() { echo "  ${SYM_INFO}  $*"; }
step() { echo; echo "  ${BBLU}${BOLD}▸ $*${RESET}"; echo; }

# Prompt with a default value.  ask VAR "Question" "default"
ask() {
    local var="$1"; local prompt="$2"; local default="${3:-}"
    local label
    [[ -n "$default" ]] && label="${prompt} ${DIM}[${default}]${RESET}: " \
                        || label="${prompt}: "
    printf "  %s" "$label"
    IFS= read -r _ans
    if [[ -z "$_ans" && -n "$default" ]]; then
        printf -v "$var" '%s' "$default"
    else
        printf -v "$var" '%s' "$_ans"
    fi
}

# yes_no VAR "Question" [y|n]   →  sets VAR to "y" or "n"
yes_no() {
    local var="$1"; local prompt="$2"; local default="${3:-n}"
    local choices
    [[ "$default" == "y" ]] && choices="${BGRN}Y${RESET}/n" || choices="y/${BGRN}N${RESET}"
    while true; do
        printf "  %s [%s]: " "$prompt" "$choices"
        IFS= read -r _yn
        _yn="${_yn:-$default}"
        case "${_yn,,}" in
            y|yes) printf -v "$var" 'y'; return ;;
            n|no)  printf -v "$var" 'n'; return ;;
            *) echo "    Please answer y or n." ;;
        esac
    done
}

# pause  — "Press Enter to continue"
pause() {
    local msg="${1:-Press Enter to continue, or Ctrl+C to abort...}"
    printf "\n  ${DIM}%s${RESET} " "$msg"
    IFS= read -r _
    echo
}

# require typed confirmation: confirm_exact "TYPE THIS"
confirm_exact() {
    local required="$1"
    local typed
    printf "  ${BYLO}Type  ${RESET}${BOLD}%s${RESET}${BYLO}  to confirm:${RESET} " "$required"
    IFS= read -r typed
    if [[ "$typed" != "$required" ]]; then
        echo
        fail "Confirmation text did not match. Aborting."
        exit 1
    fi
    echo
}

abort() {
    echo
    fail "Setup aborted: $*"
    echo
    exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# State variables — populated throughout the wizard
# ══════════════════════════════════════════════════════════════════════════════
POOL_NAME="media_pool"
RAID_TYPE="raidz2"
COMPRESSION="lz4"
ENABLE_ENCRYPTION="y"
KEY_DIR="/etc/zfs/keys"
declare -a SELECTED_DISKS=()

ENABLE_AUTOMOUNT="y"
ENABLE_TIMEMACHINE="n"
TM_COMPUTER_NAME=""
TM_BACKUP_SIZE="500g"
ENABLE_MONITORING="y"
MONITORING_LEVEL="advanced"

ZFS_BIN_PATH="/usr/local/zfs/bin"
ZPOOL="$ZFS_BIN_PATH/zpool"
ZFS="$ZFS_BIN_PATH/zfs"
LAUNCHD_PLIST_SRC="$REPO_ROOT/configs/launchd/com.local.zfs.automount.plist"

TOTAL_PHASES=9

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — LEGAL DISCLAIMER
# ══════════════════════════════════════════════════════════════════════════════
clear
banner "═" "  macOS ZFS DAS — Setup Wizard  "
cat <<'WELCOME'
  Welcome to the macOS ZFS DAS interactive installer.

  This wizard will guide you through:
    • Identifying and preparing your external drives
    • Creating an encrypted, redundant ZFS storage pool
    • Configuring optional Time Machine backups
    • Installing SwiftBar ZFS monitoring
    • Setting up automatic pool mounting on boot

WELCOME

phase_header 1 $TOTAL_PHASES "LEGAL DISCLAIMER & ACCEPTANCE"

cat <<DISCLAIMER
  ${BRED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}
  ${BRED}${BOLD}  IMPORTANT — READ CAREFULLY BEFORE PROCEEDING                             ${RESET}
  ${BRED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}

  ${BOLD}DATA LOSS WARNING${RESET}

  Creating a ZFS pool requires formatting the selected drives.  Formatting
  PERMANENTLY and IRREVERSIBLY destroys ALL existing data on those drives.
  This action CANNOT be undone.

  ${BOLD}MANUAL REVIEW REQUIRED — PARTITION COMMANDS NOT AUTO-EXECUTED${RESET}

  This installer will display the exact disk preparation commands you need
  to run.  Those commands are shown as PLAIN TEXT only and will NOT be
  executed automatically.  You must:

    1. Read each command carefully.
    2. Cross-check every disk identifier against your own 'diskutil list'
       output to confirm you are not targeting the wrong drive.
    3. Copy and execute the commands yourself in a separate Terminal window.

  ${BOLD}NO WARRANTY — NO LIABILITY${RESET}

  This software is provided "AS IS", without warranty of any kind, express
  or implied.  The authors and contributors of the macOS ZFS DAS project:

    • Accept NO legal responsibility for data loss, hardware damage,
      system instability, or any other damage resulting from the use of
      this software, whether direct, indirect, incidental, or consequential.

    • Do NOT guarantee that this software is fit for any particular purpose.

    • Are NOT liable for errors in user input, misidentified drives,
      accidental formatting of system or personal drives, or any action
      taken based on the output of this installer.

  By proceeding you confirm that:

    ✦  You have read and understood this disclaimer in full.
    ✦  You accept sole responsibility for any data loss or damage.
    ✦  You have an up-to-date backup of all important data.
    ✦  You will manually verify all drive identifiers before executing
       any disk commands.
    ✦  You are the authorised owner or administrator of this system and
       the attached storage devices.

  ${BOLD}Full license text:  ${REPO_ROOT}/LICENSE${RESET}

DISCLAIMER

printf "  ${BYLO}${BOLD}Type  I AGREE  (exactly) to accept and continue:${RESET}  "
IFS= read -r _agree
if [[ "$_agree" != "I AGREE" ]]; then
    echo
    fail "Disclaimer not accepted. Exiting."
    exit 0
fi
echo
ok "Disclaimer accepted. Proceeding."

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — SYSTEM COMPATIBILITY CHECKS
# ══════════════════════════════════════════════════════════════════════════════
phase_header 2 $TOTAL_PHASES "SYSTEM COMPATIBILITY CHECKS"

CHECKS_FAILED=0

# Root check
printf "  Checking: running as root ... "
if [[ "$EUID" -ne 0 ]]; then
    echo "${SYM_FAIL}"
    fail "This installer must be run with sudo."
    echo "  Please re-run: ${BOLD}sudo bash scripts/setup.sh${RESET}"
    exit 1
fi
echo "${SYM_OK}"

# macOS version
printf "  Checking: macOS 14+ ... "
MACOS_VER=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VER" | cut -d. -f1)
if [[ "$MACOS_MAJOR" -ge 14 ]]; then
    echo "${SYM_OK}  (${MACOS_VER})"
else
    echo "${SYM_WARN}  (${MACOS_VER}) — OpenZFS supports 10.13+; Sonoma 14+ recommended"
fi

# OpenZFS
printf "  Checking: OpenZFS at %s ... " "$ZFS_BIN_PATH"
if [[ -x "$ZPOOL" ]]; then
    ZFS_VER=$("$ZPOOL" version 2>/dev/null | head -1 || echo "unknown")
    echo "${SYM_OK}  (${ZFS_VER})"
else
    echo "${SYM_FAIL}"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fail "OpenZFS not found at ${ZFS_BIN_PATH}."
    echo
    cat <<ZFSINST
  ${BYLO}OpenZFS must be installed before this wizard can continue.${RESET}

  Download the installer for your macOS version from:
    ${BBLU}https://openzfsonosx.github.io/${RESET}

  After installing, re-run this wizard.
ZFSINST
fi

# curl + unzip (needed for SwiftBar installer)
for cmd in curl unzip diskutil; do
    printf "  Checking: %s ... " "$cmd"
    if command -v "$cmd" &>/dev/null; then
        echo "${SYM_OK}"
    else
        echo "${SYM_FAIL}"
        fail "Required command '${cmd}' not found."
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
done

# External disks present
printf "  Checking: external storage attached ... "
EXT_COUNT=$(diskutil list external 2>/dev/null | grep -c "^/dev/disk" || true)
if [[ "$EXT_COUNT" -gt 0 ]]; then
    echo "${SYM_OK}  (${EXT_COUNT} external disk(s) detected)"
else
    echo "${SYM_WARN}"
    warn "No external disks detected. Connect your DAS enclosure and re-run."
fi

echo

if [[ "$CHECKS_FAILED" -gt 0 ]]; then
    abort "$CHECKS_FAILED critical prerequisite(s) failed. Resolve them and re-run."
fi

ok "System checks passed."
pause

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — DRIVE IDENTIFICATION
# ══════════════════════════════════════════════════════════════════════════════
phase_header 3 $TOTAL_PHASES "DRIVE IDENTIFICATION"

cat <<'DRIVEINFO'
  The following is the output of  diskutil list  on your system.
  Study it carefully to identify which disks belong to your DAS enclosure.

  ─────────────────────────────────────────────────────────────────────────────
  TIPS FOR IDENTIFYING YOUR DAS DRIVES:
  • Your Mac's internal SSD is usually  disk0  (and sometimes disk1 for APFS).
  • External USB/Thunderbolt drives appear under  "external, physical"  below.
  • Never select  disk0  or any disk labelled "APFS" as your system volume.
  • If unsure, physically unplug/replug each DAS drive one at a time and run
    'diskutil list' again to see which entry appears/disappears.
  ─────────────────────────────────────────────────────────────────────────────

DRIVEINFO

diskutil list

echo
hr "─"
echo
info "Above is your complete disk list."
info "In the next step you will enter the disk identifiers for your DAS drives."
info "Example: ${BOLD}disk2 disk3 disk4 disk5${RESET}"
echo

step "Enter DAS disk identifiers"

cat <<'DISKWARNING'
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  ⚠  CRITICAL: Enter ONLY the disks that belong to your DAS enclosure.  │
  │     Entering your system disk (disk0) will destroy macOS.               │
  └─────────────────────────────────────────────────────────────────────────┘

DISKWARNING

validate_disk_id() {
    [[ "$1" =~ ^disk[0-9]+(s[0-9]+)?$ ]]
}

while true; do
    ask DISK_INPUT "DAS disk identifiers (space-separated, e.g. disk2 disk3 disk4)" ""
    if [[ -z "$DISK_INPUT" ]]; then
        warn "No disks entered. Please enter at least one disk identifier."; continue
    fi

    read -ra SELECTED_DISKS <<< "$DISK_INPUT"
    INVALID=()
    NOT_FOUND=()

    for d in "${SELECTED_DISKS[@]}"; do
        if ! validate_disk_id "$d"; then
            INVALID+=("$d")
        elif ! diskutil info "$d" &>/dev/null; then
            NOT_FOUND+=("$d")
        fi
    done

    if [[ ${#INVALID[@]} -gt 0 ]]; then
        warn "Invalid identifier(s): ${INVALID[*]}"
        warn "Expected format: diskN or diskNsM (e.g. disk2, disk3s1)"
        continue
    fi
    if [[ ${#NOT_FOUND[@]} -gt 0 ]]; then
        warn "Disk(s) not found on this system: ${NOT_FOUND[*]}"
        warn "Run 'diskutil list' again to verify the identifiers."
        continue
    fi
    break
done

echo
ok "Selected ${#SELECTED_DISKS[@]} disk(s): ${SELECTED_DISKS[*]}"

# Show detailed info for each selected disk
echo
info "Details for selected disk(s):"
hr "─"
for d in "${SELECTED_DISKS[@]}"; do
    printf "  ${BOLD}/dev/%s${RESET}\n" "$d"
    diskutil info "$d" 2>/dev/null \
        | grep -E "Device / Media Name|Disk Size|Media Type|Solid State|Protocol" \
        | sed 's/^/    /'
    echo
done
hr "─"

echo
warn "Are these definitely your DAS enclosure drives and NOT your Mac's internal disk?"
confirm_exact "YES THESE ARE MY DAS DRIVES"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 4 — DISK PREPARATION COMMANDS  (TEXT ONLY — YOU RUN THESE)
# ══════════════════════════════════════════════════════════════════════════════
phase_header 4 $TOTAL_PHASES "DISK PREPARATION COMMANDS  (TEXT ONLY)"

cat <<'PREPINTRO'
  Before a ZFS pool can be created, the target drives must be unmounted and
  their existing partition tables cleared.

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                                                                         │
  │   THIS INSTALLER WILL NOT EXECUTE THESE COMMANDS FOR YOU.              │
  │                                                                         │
  │   The commands below are provided FOR YOUR MANUAL REVIEW ONLY.         │
  │                                                                         │
  │   You must:                                                             │
  │     1. Read every command carefully.                                    │
  │     2. Verify every disk identifier is correct in  diskutil list.      │
  │     3. Open a NEW Terminal window and execute the commands yourself.    │
  │     4. Return here and press Enter only after all commands have run.   │
  │                                                                         │
  │   Running these commands on the WRONG disk will permanently destroy    │
  │   the data on that disk. The authors accept NO liability for errors.   │
  │                                                                         │
  └─────────────────────────────────────────────────────────────────────────┘

PREPINTRO

# Build the command block
echo
hr "─"
echo "  ${BOLD}${BYLO}COMMANDS TO RUN MANUALLY IN A SEPARATE TERMINAL WINDOW:${RESET}"
hr "─"
echo

cat <<'PREFLIGHT'
  # ── Step 0: Confirm you are working on the correct disks ─────────────────
  # Run this first and compare the output to what you saw in Phase 3.
  # Do NOT proceed if anything looks unexpected.

  diskutil list

PREFLIGHT

echo "  # ── Step 1: Unmount all volumes on each DAS disk ────────────────────────"
for d in "${SELECTED_DISKS[@]}"; do
    printf "  sudo diskutil unmountDisk /dev/%s\n" "$d"
done

echo
echo "  # ── Step 2: Erase partition table on each DAS disk ──────────────────────"
echo "  # This wipes all partitions and makes the drive usable as a raw ZFS vdev."
echo "  # WARNING: This PERMANENTLY destroys all data on the disk."
for d in "${SELECTED_DISKS[@]}"; do
    printf "  sudo diskutil eraseDisk free EMPTY GPT /dev/%s\n" "$d"
done

echo
echo "  # ── Step 3: Verify disks are now empty ──────────────────────────────────"
echo "  diskutil list"

echo
hr "─"
echo

warn "CROSS-CHECK REQUIREMENT"
echo
cat <<'CROSSCHECK'
  Before running any command above:

    ✦  Confirm each /dev/diskN matches the DAS drive you intend to wipe.
    ✦  Look for the disk's size and media name in  diskutil list  output.
    ✦  Physically label your drives if needed to avoid confusion.
    ✦  Ensure your Mac's system disk (typically disk0) is NOT in the list.
    ✦  Ensure Time Machine, cloud sync, and other apps are not using these
       disks right now.

  If you are unsure about any disk identifier, STOP and investigate further
  before running any command.  Data loss from disk misidentification is
  permanent and unrecoverable.

CROSSCHECK

echo "  ${BRED}${BOLD}The software provider accepts NO LEGAL RESPONSIBILITY for data loss${RESET}"
echo "  ${BRED}${BOLD}caused by executing these commands on incorrect drives.${RESET}"
echo

pause "Open a new Terminal, run the commands above, then press Enter here to continue..."

step "Verify drives are now clean"
info "Running  diskutil list  so you can confirm the drives are empty..."
echo
diskutil list
echo

yes_no PREP_DONE "Have you successfully run all preparation commands and verified the drives are empty?" "n"
if [[ "$PREP_DONE" != "y" ]]; then
    abort "Disk preparation not confirmed. Re-run setup when drives are ready."
fi
ok "Disk preparation confirmed."

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 5 — POOL CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
phase_header 5 $TOTAL_PHASES "POOL CONFIGURATION"

DISK_COUNT=${#SELECTED_DISKS[@]}

# ── Pool name ──
step "Pool name"
info "Must start with a letter; letters, numbers, hyphens, underscores only."
while true; do
    ask POOL_NAME "Pool name" "media_pool"
    if [[ ! "$POOL_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]{0,63}$ ]]; then
        warn "Invalid pool name. Use letters/numbers/hyphens/underscores, start with a letter."; continue
    fi
    if "$ZPOOL" list "$POOL_NAME" &>/dev/null; then
        warn "A pool named '${POOL_NAME}' already exists. Choose a different name."; continue
    fi
    break
done
ok "Pool name: ${BOLD}${POOL_NAME}${RESET}"

# ── RAID type ──
step "RAID type"

RAIDZ_OK_3="${GRN}✓ OK with ${DISK_COUNT} disk(s)${RESET}"
RAIDZ_WARN_3="${BYLO}⚠ Needs 3+ disks${RESET}"
RAIDZ_WARN_4="${BYLO}⚠ Needs 4+ disks (recommended)${RESET}"
RAIDZ_WARN_5="${BYLO}⚠ Needs 5+ disks${RESET}"
RAIDZ_WARN_2="${BYLO}⚠ Needs 2+ disks${RESET}"

[[ $DISK_COUNT -ge 3 ]] && R1_STATUS="$RAIDZ_OK_3" || R1_STATUS="$RAIDZ_WARN_3"
[[ $DISK_COUNT -ge 4 ]] && R2_STATUS="$RAIDZ_OK_3" || R2_STATUS="$RAIDZ_WARN_4"
[[ $DISK_COUNT -ge 5 ]] && R3_STATUS="$RAIDZ_OK_3" || R3_STATUS="$RAIDZ_WARN_5"
[[ $DISK_COUNT -ge 2 ]] && MR_STATUS="$RAIDZ_OK_3" || MR_STATUS="$RAIDZ_WARN_2"

cat <<RAIDMENU
   1) mirror   — Exact copies across 2+ drives
                 Capacity: 1 drive   |  Survives: all-but-one failure  $MR_STATUS
                 Best for: 2 drives, maximum redundancy

   2) raidz1   — Single parity (like RAID-5)
                 Capacity: N-1 drives |  Survives: 1 drive failure     $R1_STATUS
                 Best for: 3 drives, balanced

   3) raidz2   — Double parity (like RAID-6) ${BOLD}← Recommended${RESET}
                 Capacity: N-2 drives |  Survives: 2 drive failures    $R2_STATUS
                 Best for: 4–8 drives, production workloads

   4) raidz3   — Triple parity
                 Capacity: N-3 drives |  Survives: 3 drive failures    $R3_STATUS
                 Best for: 7+ drives, mission-critical

   5) stripe   — No redundancy, maximum speed/capacity
                 Capacity: 100%       |  Survives: 0 failures
                 ${BRED}WARNING: Any single drive failure = total data loss${RESET}

RAIDMENU

while true; do
    ask RAID_CHOICE "Select RAID type (1–5)" "3"
    case "$RAID_CHOICE" in
        1) RAID_TYPE="mirror";  MIN_DISKS=2 ;;
        2) RAID_TYPE="raidz1";  MIN_DISKS=3 ;;
        3) RAID_TYPE="raidz2";  MIN_DISKS=4 ;;
        4) RAID_TYPE="raidz3";  MIN_DISKS=5 ;;
        5) RAID_TYPE="stripe";  MIN_DISKS=1 ;;
        *) warn "Enter a number from 1 to 5."; continue ;;
    esac
    if [[ $DISK_COUNT -lt $MIN_DISKS ]]; then
        warn "${RAID_TYPE} requires at least ${MIN_DISKS} disks; you selected ${DISK_COUNT}."
        warn "Either select fewer parity levels or add more drives."
        continue
    fi
    if [[ "$RAID_TYPE" == "stripe" ]]; then
        echo
        warn "stripe offers NO redundancy. A single drive failure destroys your data."
        confirm_exact "I ACCEPT THE RISK OF NO REDUNDANCY"
    fi
    break
done
ok "RAID type: ${BOLD}${RAID_TYPE}${RESET}"

# ── Compression ──
step "Compression"
cat <<'COMPMENU'
   1) lz4    — Fast, near-zero CPU overhead  ← Recommended for most users
   2) zstd   — Better ratio, still fast      ← Recommended for media archives
   3) gzip-6 — Maximum compression, slower
   4) off    — No compression

COMPMENU
while true; do
    ask COMP_CHOICE "Select compression (1–4)" "1"
    case "$COMP_CHOICE" in
        1) COMPRESSION="lz4"    ;;
        2) COMPRESSION="zstd"   ;;
        3) COMPRESSION="gzip-6" ;;
        4) COMPRESSION="off"    ;;
        *) warn "Enter 1–4."; continue ;;
    esac
    break
done
ok "Compression: ${BOLD}${COMPRESSION}${RESET}"

# ── Encryption ──
step "Encryption"
info "AES-256-GCM encryption at rest.  A 256-bit random key is generated and"
info "stored at ${KEY_DIR}/<poolname>.key (root-only, chmod 600)."
echo
yes_no ENABLE_ENCRYPTION "Enable AES-256-GCM encryption?" "y"

if [[ "$ENABLE_ENCRYPTION" == "y" ]]; then
    ok "Encryption: ${BOLD}enabled (AES-256-GCM)${RESET}"
    warn "You MUST back up the key file after setup or your data is unrecoverable."
else
    warn "Encryption disabled. Your data will be stored in plaintext."
    ok "Encryption: ${BOLD}disabled${RESET}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 6 — OPTIONAL FEATURES
# ══════════════════════════════════════════════════════════════════════════════
phase_header 6 $TOTAL_PHASES "OPTIONAL FEATURES"

# ── Auto-mount on boot ──
step "Auto-mount on boot (LaunchDaemon)"
info "Installs a LaunchDaemon that automatically imports and mounts your ZFS"
info "pool when the Mac boots. Requires the pool to be connected at startup."
echo
yes_no ENABLE_AUTOMOUNT "Install auto-mount LaunchDaemon?" "y"
[[ "$ENABLE_AUTOMOUNT" == "y" ]] && ok "Auto-mount: ${BOLD}enabled${RESET}" || ok "Auto-mount: ${BOLD}skipped${RESET}"

# ── Time Machine ──
step "Time Machine backups on ZFS"
info "Creates a ZFS dataset and SMB share for network Time Machine backups."
info "Requires SMB to be enabled (System Settings → Sharing → File Sharing)."
echo
yes_no ENABLE_TIMEMACHINE "Set up Time Machine on this pool?" "n"

if [[ "$ENABLE_TIMEMACHINE" == "y" ]]; then
    echo
    info "The Time Machine share will be created as a ZFS dataset."
    echo
    while true; do
        ask TM_COMPUTER_NAME "Mac identifier for this backup (e.g. MacMini, MacBookPro)" ""
        if [[ -z "$TM_COMPUTER_NAME" ]]; then
            warn "Computer name cannot be empty."; continue
        fi
        if [[ ! "$TM_COMPUTER_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]{0,63}$ ]]; then
            warn "Use letters, numbers, hyphens, underscores. Must start with a letter."; continue
        fi
        break
    done
    echo
    # Show available pool space as guidance
    info "Recommendation: set quota to 2–3× your Mac's used storage."
    while true; do
        ask TM_BACKUP_SIZE "Backup quota (e.g. 500g, 1t, 2t)" "500g"
        if [[ ! "$TM_BACKUP_SIZE" =~ ^[0-9]+[gGtTmM]$ ]]; then
            warn "Format: number followed by g/G/t/T/m/M  (e.g. 500g, 1t)"; continue
        fi
        break
    done
    ok "Time Machine: ${BOLD}enabled${RESET}  (name: ${TM_COMPUTER_NAME}, quota: ${TM_BACKUP_SIZE})"
else
    ok "Time Machine: ${BOLD}skipped${RESET}"
fi

# ── SwiftBar monitoring ──
step "SwiftBar menu bar monitoring"
info "Downloads and installs SwiftBar (MIT, Ameba Labs) and the ZFS monitoring"
info "plugins bundled with this project. No Homebrew required."
echo
yes_no ENABLE_MONITORING "Install SwiftBar ZFS monitoring?" "y"

if [[ "$ENABLE_MONITORING" == "y" ]]; then
    echo
    cat <<'MONLEVEL'
   1) Basic    — Pool health, capacity, drive status, scrub, Time Machine
   2) Advanced — All basic + capacity bars, ARC stats, trend arrows,
                 snapshot management, encryption status  ← Recommended

MONLEVEL
    while true; do
        ask MON_CHOICE "Select monitoring level (1–2)" "2"
        case "$MON_CHOICE" in
            1) MONITORING_LEVEL="monitor"  ;;
            2) MONITORING_LEVEL="advanced" ;;
            *) warn "Enter 1 or 2."; continue ;;
        esac
        break
    done
    ok "Monitoring: ${BOLD}enabled${RESET}  (level: ${MONITORING_LEVEL})"
else
    ok "Monitoring: ${BOLD}skipped${RESET}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 7 — FULL REVIEW & FINAL CONFIRMATION
# ══════════════════════════════════════════════════════════════════════════════
phase_header 7 $TOTAL_PHASES "FULL REVIEW & FINAL CONFIRMATION"

cat <<REVIEW
  ${BOLD}${WHT}Your selected configuration:${RESET}
  ${DIM}───────────────────────────────────────────────────────────────────────────${RESET}

  ${BOLD}Pool:${RESET}
    Name          ${CYN}${POOL_NAME}${RESET}
    RAID type     ${CYN}${RAID_TYPE}${RESET}
    Disks (${#SELECTED_DISKS[@]})    ${CYN}${SELECTED_DISKS[*]}${RESET}
    Compression   ${CYN}${COMPRESSION}${RESET}
    Encryption    ${CYN}$([ "$ENABLE_ENCRYPTION" = "y" ] && echo "AES-256-GCM (key: ${KEY_DIR}/${POOL_NAME}.key)" || echo "disabled")${RESET}

  ${BOLD}Optional features:${RESET}
    Auto-mount    ${CYN}$([ "$ENABLE_AUTOMOUNT" = "y"  ] && echo "Yes — LaunchDaemon will be installed" || echo "No")${RESET}
    Time Machine  ${CYN}$([ "$ENABLE_TIMEMACHINE" = "y" ] && echo "Yes — name: ${TM_COMPUTER_NAME}, quota: ${TM_BACKUP_SIZE}" || echo "No")${RESET}
    SwiftBar      ${CYN}$([ "$ENABLE_MONITORING" = "y"  ] && echo "Yes — ${MONITORING_LEVEL} plugin" || echo "No")${RESET}

  ${DIM}───────────────────────────────────────────────────────────────────────────${RESET}

  ${BOLD}ZFS pool creation command (for your reference):${RESET}
REVIEW

# Build the zpool create preview
DISK_ARGS=""
for d in "${SELECTED_DISKS[@]}"; do DISK_ARGS+=" /dev/${d}"; done

ENC_FLAGS=""
if [[ "$ENABLE_ENCRYPTION" == "y" ]]; then
    ENC_FLAGS="\n    -O encryption=aes-256-gcm \\\\\n    -O keyformat=raw \\\\\n    -O keylocation=file://${KEY_DIR}/${POOL_NAME}.key \\\\"
fi

if [[ "$RAID_TYPE" == "stripe" ]]; then
    VDEV_LINE="    ${POOL_NAME}${DISK_ARGS}"
else
    VDEV_LINE="    ${POOL_NAME} ${RAID_TYPE}${DISK_ARGS}"
fi

printf "\n  ${DIM}sudo zpool create \\\\\n"
printf "    -o ashift=12 \\\\\n"
printf "    -O compression=%s \\\\\n" "$COMPRESSION"
printf "    -O atime=off \\\\"
if [[ "$ENABLE_ENCRYPTION" == "y" ]]; then
    printf "\n    -O encryption=aes-256-gcm \\\\\n"
    printf "    -O keyformat=raw \\\\\n"
    printf "    -O keylocation=file://%s/%s.key \\\\" "$KEY_DIR" "$POOL_NAME"
fi
printf "\n    %s\n${RESET}\n" "$VDEV_LINE"

echo
cat <<FINALWARN
  ${BRED}${BOLD}┌──────────────────────────────────────────────────────────────────────────┐${RESET}
  ${BRED}${BOLD}│  FINAL WARNING                                                           │${RESET}
  ${BRED}${BOLD}│                                                                          │${RESET}
  ${BRED}${BOLD}│  Proceeding will:                                                        │${RESET}
  ${BRED}${BOLD}│    • Create a ZFS pool across the disks listed above                    │${RESET}
  ${BRED}${BOLD}│    • The selected disks must already be wiped (done in Phase 4)         │${RESET}
  ${BRED}${BOLD}│    • This action cannot be undone without losing all pool data           │${RESET}
  ${BRED}${BOLD}│                                                                          │${RESET}
  ${BRED}${BOLD}│  The software provider accepts NO legal responsibility for data loss.   │${RESET}
  ${BRED}${BOLD}└──────────────────────────────────────────────────────────────────────────┘${RESET}

FINALWARN

warn "Last chance to abort. Press Ctrl+C now to cancel without making any changes."
echo
confirm_exact "CREATE THE POOL"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 8 — AUTOMATED INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════
phase_header 8 $TOTAL_PHASES "AUTOMATED INSTALLATION"
set -euo pipefail   # Strict mode now — we're executing real operations

run_step() {
    local label="$1"; shift
    printf "  ${BLU}▸${RESET} %s ... " "$label"
    if "$@" &>/tmp/zfs-setup-step.log 2>&1; then
        echo "${SYM_OK}"
    else
        echo "${SYM_FAIL}"
        fail "Step failed. Log:"
        sed 's/^/    /' /tmp/zfs-setup-step.log
        abort "Installation failed at: ${label}"
    fi
}

# ── 8a: Encryption key ──
if [[ "$ENABLE_ENCRYPTION" == "y" ]]; then
    step "Generating encryption key"
    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR"
    chown root:wheel "$KEY_DIR"

    KEY_FILE="${KEY_DIR}/${POOL_NAME}.key"
    if [[ -f "$KEY_FILE" ]]; then
        warn "Key file already exists: ${KEY_FILE}. Using existing key."
    else
        dd if=/dev/random of="$KEY_FILE" bs=32 count=1 2>/dev/null
        chmod 600 "$KEY_FILE"
        chown root:wheel "$KEY_FILE"
        ok "Key generated: ${KEY_FILE}"
    fi

    echo
    warn "ENCRYPTION KEY BACKUP — ACTION REQUIRED"
    echo
    info "Your encryption key has been generated at:"
    echo "    ${BOLD}${KEY_FILE}${RESET}"
    echo
    info "Key fingerprint (SHA-256):"
    echo "    ${BOLD}$(shasum -a 256 "$KEY_FILE" | awk '{print $1}')${RESET}"
    echo
    cat <<'KEYBACKUP'
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  CRITICAL: Back up this key file NOW, before using the pool.           │
  │                                                                         │
  │  Recommended backup methods:                                           │
  │    • Copy to an encrypted USB drive kept offline                       │
  │    • Store in a password manager (e.g. 1Password, Bitwarden)          │
  │    • Print the fingerprint and store in a safe                        │
  │                                                                         │
  │  Without this key, your data is PERMANENTLY UNRECOVERABLE.            │
  └─────────────────────────────────────────────────────────────────────────┘

KEYBACKUP
    confirm_exact "I HAVE NOTED THE KEY LOCATION"
fi

# ── 8b: Create ZFS pool ──
step "Creating ZFS pool"
DISK_DEV_PATHS=()
for d in "${SELECTED_DISKS[@]}"; do DISK_DEV_PATHS+=("/dev/$d"); done

info "Running: zpool create ..."
if [[ "$ENABLE_ENCRYPTION" == "y" ]]; then
    "$ZPOOL" create -f \
        -o ashift=12 \
        -O compression="$COMPRESSION" \
        -O atime=off \
        -O encryption=aes-256-gcm \
        -O keyformat=raw \
        -O keylocation="file://${KEY_DIR}/${POOL_NAME}.key" \
        "$POOL_NAME" \
        $( [[ "$RAID_TYPE" == "stripe" ]] || printf '%s' "$RAID_TYPE" ) \
        "${DISK_DEV_PATHS[@]}"
else
    "$ZPOOL" create -f \
        -o ashift=12 \
        -O compression="$COMPRESSION" \
        -O atime=off \
        "$POOL_NAME" \
        $( [[ "$RAID_TYPE" == "stripe" ]] || printf '%s' "$RAID_TYPE" ) \
        "${DISK_DEV_PATHS[@]}"
fi
ok "Pool ${BOLD}${POOL_NAME}${RESET} created."

# ── 8c: Create default datasets ──
step "Creating default datasets"
run_step "Create ${POOL_NAME}/data"    "$ZFS" create "${POOL_NAME}/data"
run_step "Create ${POOL_NAME}/backups" "$ZFS" create "${POOL_NAME}/backups"
ok "Datasets created."

# ── 8d: Write config file ──
step "Writing configuration file"
CONFIG_DEST="/usr/local/etc/zfs-das.conf"
mkdir -p "$(dirname "$CONFIG_DEST")"
cat > "$CONFIG_DEST" <<CONF
# zfs-das.conf — generated by setup.sh on $(date)
POOL_NAME="${POOL_NAME}"
ZFS_BIN_PATH="${ZFS_BIN_PATH}"
CAPACITY_WARNING=70
CAPACITY_CRITICAL=85
FRAG_WARNING=30
CONF

if [[ "$ENABLE_TIMEMACHINE" == "y" ]]; then
    printf 'TM_VOLUME_NAME="%s-TM"\n' "$TM_COMPUTER_NAME" >> "$CONFIG_DEST"
fi
chmod 644 "$CONFIG_DEST"
ok "Config written: ${CONFIG_DEST}"

# ── 8e: Auto-mount LaunchDaemon ──
if [[ "$ENABLE_AUTOMOUNT" == "y" ]]; then
    step "Installing auto-mount LaunchDaemon"
    AUTOMOUNT_SCRIPT="/usr/local/bin/zfs-automount.sh"
    PLIST_DEST="/Library/LaunchDaemons/com.local.zfs.automount.plist"

    cp "$REPO_ROOT/scripts/zfs-automount.sh" "$AUTOMOUNT_SCRIPT"
    chmod +x "$AUTOMOUNT_SCRIPT"
    chown root:wheel "$AUTOMOUNT_SCRIPT"

    # Patch pool name in automount script if it contains the default
    sed -i '' "s|POOL_NAME=\"media_pool\"|POOL_NAME=\"${POOL_NAME}\"|g" "$AUTOMOUNT_SCRIPT"

    cp "$LAUNCHD_PLIST_SRC" "$PLIST_DEST"
    chown root:wheel "$PLIST_DEST"
    chmod 644 "$PLIST_DEST"

    launchctl load "$PLIST_DEST" 2>/dev/null || true
    ok "LaunchDaemon installed and loaded."
fi

# ── 8f: Time Machine ──
if [[ "$ENABLE_TIMEMACHINE" == "y" ]]; then
    step "Setting up Time Machine dataset"
    TM_DATASET="${POOL_NAME}/timemachine"
    TM_QUOTA="${TM_BACKUP_SIZE^^}"   # normalise to uppercase unit

    run_step "Create ${TM_DATASET}"            "$ZFS" create "$TM_DATASET"
    run_step "Set quota=${TM_QUOTA}"           "$ZFS" set quota="$TM_QUOTA" "$TM_DATASET"
    run_step "Set atime=off"                   "$ZFS" set atime=off "$TM_DATASET"
    run_step "Set permissions (chmod 770)"     chmod 770 "/Volumes/${POOL_NAME}/timemachine"

    ok "Time Machine dataset ready at /Volumes/${POOL_NAME}/timemachine"
    echo
    info "To complete Time Machine setup, configure SMB sharing:"
    info "  sudo bash scripts/setup-timemachine.sh"
fi

# ── 8g: SwiftBar monitoring ──
if [[ "$ENABLE_MONITORING" == "y" ]]; then
    step "Installing SwiftBar monitoring"
    PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"

    # Drop elevated context for SwiftBar (it's a user-space GUI app)
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(eval echo "~${REAL_USER}")
    PLUGIN_DIR="${REAL_HOME}/Library/Application Support/SwiftBar/Plugins"

    info "Installing SwiftBar as user: ${REAL_USER}"
    sudo -u "$REAL_USER" bash "$REPO_ROOT/scripts/install-swiftbar.sh" \
        --plugin-dir "$PLUGIN_DIR"

    # Activate only the chosen plugin level; disable the other
    if [[ "$MONITORING_LEVEL" == "monitor" ]]; then
        ACTIVE_PLUGIN="${PLUGIN_DIR}/zfs-monitor.30s.sh"
        INACTIVE_PLUGIN="${PLUGIN_DIR}/zfs-advanced.30s.sh"
    else
        ACTIVE_PLUGIN="${PLUGIN_DIR}/zfs-advanced.30s.sh"
        INACTIVE_PLUGIN="${PLUGIN_DIR}/zfs-monitor.30s.sh"
    fi

    # Disable inactive plugin by adding a .disabled extension if present
    if [[ -f "$INACTIVE_PLUGIN" ]]; then
        mv "$INACTIVE_PLUGIN" "${INACTIVE_PLUGIN}.disabled"
        ok "Deactivated: $(basename "$INACTIVE_PLUGIN")"
    fi

    ok "Active plugin: $(basename "$ACTIVE_PLUGIN")"
fi

# ── 8h: Pool status ──
echo
step "Verifying pool"
"$ZPOOL" status "$POOL_NAME"
echo
"$ZFS" list -r "$POOL_NAME"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 9 — COMPLETION
# ══════════════════════════════════════════════════════════════════════════════
set +euo    # Back to permissive mode for the completion output

phase_header 9 $TOTAL_PHASES "SETUP COMPLETE"

cat <<DONE
  ${BGRN}${BOLD}Your macOS ZFS DAS is ready!${RESET}

  ${BOLD}What was set up:${RESET}
DONE

ok "Pool ${BOLD}${POOL_NAME}${RESET} (${RAID_TYPE}) on ${DISK_COUNT} disk(s)"
ok "Dataset /data  →  ${BOLD}/Volumes/${POOL_NAME}/data${RESET}"
ok "Dataset /backups  →  ${BOLD}/Volumes/${POOL_NAME}/backups${RESET}"
[[ "$ENABLE_ENCRYPTION"  == "y" ]] && ok "AES-256-GCM encryption enabled"
[[ "$ENABLE_AUTOMOUNT"   == "y" ]] && ok "Auto-mount LaunchDaemon installed"
[[ "$ENABLE_TIMEMACHINE" == "y" ]] && ok "Time Machine dataset at ${POOL_NAME}/timemachine (quota: ${TM_BACKUP_SIZE})"
[[ "$ENABLE_MONITORING"  == "y" ]] && ok "SwiftBar monitoring installed (${MONITORING_LEVEL})"

echo

if [[ "$ENABLE_ENCRYPTION" == "y" ]]; then
    echo "  ${BYLO}${BOLD}⚠  ENCRYPTION KEY REMINDER${RESET}"
    echo "  ${BYLO}   Key location:  ${KEY_DIR}/${POOL_NAME}.key${RESET}"
    echo "  ${BYLO}   Back this up NOW to an offline secure location.${RESET}"
    echo "  ${BYLO}   Losing this key = losing all data permanently.${RESET}"
    echo
fi

cat <<NEXTSTEPS
  ${BOLD}Suggested next steps:${RESET}

    ${SYM_ARROW} ${BOLD}Back up your encryption key${RESET}
        Copy ${KEY_DIR}/${POOL_NAME}.key to a secure USB drive or password manager.

    ${SYM_ARROW} ${BOLD}Run a first scrub to verify hardware integrity${RESET}
        sudo ${ZPOOL} scrub ${POOL_NAME}

    ${SYM_ARROW} ${BOLD}Schedule monthly scrubs${RESET}
        sudo bash scripts/zfs-maintenance.sh

NEXTSTEPS

if [[ "$ENABLE_TIMEMACHINE" == "y" ]]; then
    cat <<TM_NEXTSTEP
    ${SYM_ARROW} ${BOLD}Complete Time Machine SMB sharing${RESET}
        sudo bash scripts/setup-timemachine.sh
        Then open System Settings → Time Machine → Add Backup Disk

TM_NEXTSTEP
fi

if [[ "$ENABLE_MONITORING" == "y" ]]; then
    cat <<MON_NEXTSTEP
    ${SYM_ARROW} ${BOLD}Check your menu bar${RESET}
        Look for the ZFS pool icon. Click it for pool health details.
        It refreshes automatically every 30 seconds.

MON_NEXTSTEP
fi

cat <<DOCS
    ${SYM_ARROW} ${BOLD}Full documentation${RESET}
        https://github.com/contextinit/macos-zfs-das

DOCS

hr "═"
echo
info "Configuration file:  ${CONFIG_DEST}"
info "Setup completed at:  $(date)"
echo

# ══════════════════════════════════════════════════════════════════════════════
rm -f /tmp/zfs-setup-step.log
