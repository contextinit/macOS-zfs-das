#!/bin/bash

###############################################################################
# ShellCheck Test Runner
# 
# Purpose: Run shellcheck on all bash scripts in the project
# Usage: ./tests/test-shellcheck.sh
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}=========================================="
echo "ShellCheck Linting Test"
echo -e "==========================================${NC}"
echo ""

# Check if shellcheck is installed
if ! command -v shellcheck &>/dev/null; then
    echo -e "${RED}✗ shellcheck is not installed${NC}"
    echo ""
    echo "Install shellcheck:"
    echo "  macOS: brew install shellcheck"
    echo "  Linux: apt-get install shellcheck"
    exit 1
fi

echo -e "${GREEN}✓ shellcheck found: $(shellcheck --version | head -1)${NC}"
echo ""

# Find all bash scripts
SCRIPTS=(
    "$PROJECT_ROOT/scripts/zfs-automount.sh"
    "$PROJECT_ROOT/scripts/zfs-maintenance.sh"
    "$PROJECT_ROOT/scripts/setup-timemachine.sh"
    "$PROJECT_ROOT/scripts/create-pool.sh"
    "$PROJECT_ROOT/scripts/setup-encryption.sh"
    "$PROJECT_ROOT/scripts/setup-monitoring.sh"
    "$PROJECT_ROOT/swiftbar/zfs-monitor.30s.sh"
    "$PROJECT_ROOT/swiftbar/zfs-advanced.30s.sh"
)

TOTAL=0
PASSED=0
FAILED=0

echo "Checking scripts..."
echo ""

# Run shellcheck on each script
for script in "${SCRIPTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    
    if [ ! -f "$script" ]; then
        echo -e "${YELLOW}⊘ SKIP: $(basename "$script") (not found)${NC}"
        continue
    fi
    
    echo -n "Testing $(basename "$script")... "
    
    if shellcheck "$script" 2>&1 | tee "/tmp/shellcheck_$$.log" | grep -q "^In.*line"; then
        FAILED=$((FAILED + 1))
        echo -e "${RED}✗ FAIL${NC}"
        echo ""
        cat "/tmp/shellcheck_$$.log"
        echo ""
    else
        PASSED=$((PASSED + 1))
        echo -e "${GREEN}✓ PASS${NC}"
    fi
    
    rm -f "/tmp/shellcheck_$$.log"
done

echo ""
echo -e "${BLUE}=========================================="
echo "Test Results"
echo -e "==========================================${NC}"
echo "Total scripts: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All shellcheck tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some shellcheck tests failed${NC}"
    exit 1
fi
