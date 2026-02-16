#!/bin/bash

###############################################################################
# Integration Test Suite - Script Validation
# 
# Purpose: Validate script structure and basic functionality
# Usage: ./tests/test-scripts.sh
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}=========================================="
echo "Script Validation Test"
echo -e "==========================================${NC}"
echo ""

PASSED=0
FAILED=0

# Test 1: All referenced scripts exist
echo -n "Test 1: All installation scripts exist... "
MISSING=0
for script in create-pool.sh setup-encryption.sh setup-monitoring.sh; do
    if [ ! -f "$PROJECT_ROOT/scripts/$script" ]; then
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($MISSING missing)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 2: All scripts are executable
echo -n "Test 2: All scripts are executable... "
NON_EXEC=0
for script in "$PROJECT_ROOT"/scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        NON_EXEC=$((NON_EXEC + 1))
    fi
done

if [ $NON_EXEC -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($NON_EXEC not executable)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 3: All scripts have shebang on line 1
echo -n "Test 3: All scripts have proper shebang... "
BAD_SHEBANG=0
for script in "$PROJECT_ROOT"/scripts/*.sh; do
    if [ -f "$script" ]; then
        FIRST_LINE=$(head -1 "$script")
        if [[ ! "$FIRST_LINE" =~ ^#!/bin/bash ]]; then
            BAD_SHEBANG=$((BAD_SHEBANG + 1))
        fi
    fi
done

if [ $BAD_SHEBANG -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($BAD_SHEBANG wrong shebang)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 4: Scripts have valid bash syntax
echo -n "Test 4: All scripts have valid syntax... "
SYNTAX_ERRORS=0
for script in "$PROJECT_ROOT"/scripts/*.sh; do
    if [ -f "$script" ]; then
        if ! bash -n "$script" 2>/dev/null; then
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($SYNTAX_ERRORS syntax errors)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 5: Scripts use full paths for commands
echo -n "Test 5: Critical scripts use full paths... "
MISSING_PATHS=0
for script in "$PROJECT_ROOT"/scripts/zfs-automount.sh "$PROJECT_ROOT"/scripts/zfs-maintenance.sh; do
    if [ -f "$script" ]; then
        # Check if they define ZFS_BIN_PATH or use full paths
        if ! grep -q 'ZFS_BIN_PATH=' "$script" && ! grep -q '"/usr/local/zfs/bin/zpool"' "$script"; then
            MISSING_PATHS=$((MISSING_PATHS + 1))
        fi
    fi
done

if [ $MISSING_PATHS -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($MISSING_PATHS without paths)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 6: SwiftBar plugins exist
echo -n "Test 6: SwiftBar plugins exist... "
PLUGINS_EXIST=0
if [ -f "$PROJECT_ROOT/swiftbar/zfs-monitor.30s.sh" ]; then
    PLUGINS_EXIST=$((PLUGINS_EXIST + 1))
fi
if [ -f "$PROJECT_ROOT/swiftbar/zfs-advanced.30s.sh" ]; then
    PLUGINS_EXIST=$((PLUGINS_EXIST + 1))
fi

if [ $PLUGINS_EXIST -eq 2 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL (found $PLUGINS_EXIST/2)${NC}"
    FAILED=$((FAILED + 1))
fi

# Summary
echo ""
echo -e "${BLUE}=========================================="
echo "Test Results"
echo -e "==========================================${NC}"
echo "Total tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All script validation tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
