#!/bin/bash

###############################################################################
# Integration Test Suite - Config System
# 
# Purpose: Test that all scripts properly source and use config files
# Usage: ./tests/test-config-integration.sh
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}=========================================="
echo "Config Integration Test"
echo -e "==========================================${NC}"
echo ""

PASSED=0
FAILED=0

# Test 1: Config file exists
echo -n "Test 1: Config file exists... "
if [ -f "$PROJECT_ROOT/configs/zfs-das.conf" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 2: Config file is valid bash syntax
echo -n "Test 2: Config file has valid syntax... "
if bash -n "$PROJECT_ROOT/configs/zfs-das.conf" 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 3: Scripts source config files
echo -n "Test 3: Scripts contain config sourcing... "
SCRIPTS_WITH_CONFIG=0
for script in "$PROJECT_ROOT"/scripts/*.sh "$PROJECT_ROOT"/swiftbar/*.sh; do
    if [ -f "$script" ] && grep -q "source.*zfs-das.conf" "$script"; then
        SCRIPTS_WITH_CONFIG=$((SCRIPTS_WITH_CONFIG + 1))
    fi
done

if [ $SCRIPTS_WITH_CONFIG -ge 4 ]; then
    echo -e "${GREEN}✓ PASS ($SCRIPTS_WITH_CONFIG scripts)${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL (only $SCRIPTS_WITH_CONFIG scripts)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 4: No hardcoded pool names in scripts (should use $POOL_NAME)
echo -n "Test 4: Scripts use variable instead of hardcoded pool... "
HARDCODED_COUNT=0
for script in "$PROJECT_ROOT"/scripts/zfs-automount.sh "$PROJECT_ROOT"/scripts/zfs-maintenance.sh; do
    if [ -f "$script" ] && grep -E 'import.*"media_pool"' "$script" | grep -v "#" &>/dev/null; then
        HARDCODED_COUNT=$((HARDCODED_COUNT + 1))
    fi
done

if [ $HARDCODED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($HARDCODED_COUNT hardcoded references)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 5: Config has required variables
echo -n "Test 5: Config has required variables... "
REQUIRED_VARS=("POOL_NAME" "ZFS_BIN_PATH" "ENABLE_TIME_MACHINE")
MISSING_VARS=0

for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^${var}=" "$PROJECT_ROOT/configs/zfs-das.conf"; then
        MISSING_VARS=$((MISSING_VARS + 1))
    fi
done

if [ $MISSING_VARS -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL ($MISSING_VARS missing vars)${NC}"
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
    echo -e "${GREEN}✓ All config integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
