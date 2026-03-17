#!/bin/bash

###############################################################################
# Prerequisites Checker
# 
# Purpose: Verify system has all requirements for ZFS DAS
# Usage: ./scripts/check-prerequisites.sh
###############################################################################

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════╗"
echo "║   ZFS DAS Prerequisites Check        ║"
echo -e "╚═══════════════════════════════════════╝${NC}"
echo ""

PASSED=0
FAILED=0
WARNINGS=0

# Check 1: macOS Version
echo -n "1. macOS Version (10.13+)... "
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
MACOS_MINOR=$(echo "$MACOS_VERSION" | cut -d. -f2)

if [ "$MACOS_MAJOR" -ge 11 ] || ([ "$MACOS_MAJOR" -eq 10 ] && [ "$MACOS_MINOR" -ge 13 ]); then
    echo -e "${GREEN}✓ PASS${NC} ($MACOS_VERSION)"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} ($MACOS_VERSION)"
    echo "   OpenZFS requires macOS 10.13 or later"
    FAILED=$((FAILED + 1))
fi

# Check 2: OpenZFS Installed
echo -n "2. OpenZFS installed... "
if [ -x "/usr/local/zfs/bin/zpool" ]; then
    ZFS_VERSION=$(/usr/local/zfs/bin/zpool --version 2>&1 | head -1)
    echo -e "${GREEN}✓ PASS${NC} ($ZFS_VERSION)"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "   Install from: https://openzfsonosx.github.io/"
    FAILED=$((FAILED + 1))
fi

# Check 3: Bash Version
echo -n "3. Bash 3.2+... "
BASH_VERSION=$(/bin/bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
BASH_MAJOR=$(echo "$BASH_VERSION" | cut -d. -f1)

if [ "$BASH_MAJOR" -ge 3 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($BASH_VERSION)"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} ($BASH_VERSION)"
    FAILED=$((FAILED + 1))
fi

# Check 4: Homebrew (optional but recommended)
echo -n "4. Homebrew (optional)... "
if command -v brew &>/dev/null; then
    BREW_VERSION=$(brew --version | head -1)
    echo -e "${GREEN}✓ PASS${NC} ($BREW_VERSION)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⊘ SKIP${NC} (not installed)"
    echo "   Recommended for SwiftBar and shellcheck"
    echo "   Install from: https://brew.sh/"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 5: SwiftBar (optional)
echo -n "5. SwiftBar (optional)... "
if [ -d "/Applications/SwiftBar.app" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⊘ SKIP${NC} (not installed)"
    echo "   Required for menu bar monitoring"
    echo "   Install: bash scripts/install-swiftbar.sh"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 6: Available Disk Space
echo -n "6. Available disk space (> 10GB)... "
AVAILABLE=$(df -g / | tail -1 | awk '{print $4}')

if [ "$AVAILABLE" -gt 10 ]; then
    echo -e "${GREEN}✓ PASS${NC} (${AVAILABLE}GB available)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (${AVAILABLE}GB available)"
    echo "   At least 10GB recommended for ZFS operations"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 7: DAS Connected (if pool configured)
echo -n "7. External storage... "
EXTERNAL_COUNT=$(diskutil list external | grep -c "/dev/disk" || echo "0")

if [ "$EXTERNAL_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($EXTERNAL_COUNT external disk(s) detected)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⊘ SKIP${NC} (no external disks detected)"
    echo "   Connect DAS before creating pool"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 8: Root Access
echo -n "8. Root access available... "
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC} (sudo configured)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo "   ZFS operations require root privileges"
    echo "   You will be prompted for password when needed"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 9: Mail Command (for email alerts)
echo -n "9. Mail command (optional)... "
if command -v mail &>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⊘ SKIP${NC} (not configured)"
    echo "   Required for email alerts"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 10: ShellCheck (optional, for development)
echo -n "10. ShellCheck (optional)... "
if command -v shellcheck &>/dev/null; then
    SHELLCHECK_VERSION=$(shellcheck --version | grep version: | awk '{print $2}')
    echo -e "${GREEN}✓ PASS${NC} ($SHELLCHECK_VERSION)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⊘ SKIP${NC} (not installed)"
    echo "   Recommended for development"
    echo "   Install: brew install shellcheck"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════╗"
echo "║   Results                             ║"
echo -e "╚═══════════════════════════════════════╝${NC}"
echo ""
echo "Total Checks: $((PASSED + FAILED + WARNINGS))"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All prerequisites met!${NC}"
        echo "Ready to proceed with ZFS DAS setup."
        exit 0
    else
        echo -e "${YELLOW}⚠ Prerequisites mostly met${NC}"
        echo "Some optional components missing, but you can proceed."
        echo "Install missing components for full functionality."
        exit 0
    fi
else
    echo -e "${RED}✗ Missing critical prerequisites${NC}"
    echo "Please install required components before proceeding."
    exit 1
fi
