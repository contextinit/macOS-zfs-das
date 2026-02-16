#!/bin/bash

###############################################################################
# Test Runner - Run All Tests
# 
# Purpose: Execute all test suites
# Usage: ./tests/run-all-tests.sh
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║   macOS ZFS DAS - Test Suite         ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"
echo ""

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Make all test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

# Run each test suite
run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    echo "-------------------------------------------"
    
    if [ -f "$test_script" ] && [ -x "$test_script" ]; then
        if "$test_script"; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            echo ""
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            echo ""
        fi
    else
        echo -e "${RED}✗ Test script not found or not executable${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        echo ""
    fi
}

# Run all test suites
run_test_suite "$SCRIPT_DIR/test-shellcheck.sh" "ShellCheck Linting"
run_test_suite "$SCRIPT_DIR/test-scripts.sh" "Script Validation"
run_test_suite "$SCRIPT_DIR/test-config-integration.sh" "Config Integration"

# Final summary
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║   Overall Test Results                ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Total test suites: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"

if [ $FAILED_SUITES -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_SUITES${NC}"
    echo ""
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✓ All test suites passed!${NC}"
    echo ""
    echo "The project passes all automated tests. ✨"
    exit 0
fi
