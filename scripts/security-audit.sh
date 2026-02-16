#!/bin/bash

###############################################################################
# Security Audit Script
# 
# Purpose: Audit encryption key security and permissions
# Usage: sudo ./scripts/security-audit.sh
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
KEY_DIR="/etc/zfs/keys"

echo -e "${BLUE}=========================================="
echo "ZFS Encryption Security Audit"
echo -e "==========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠  Not running as root - some checks may be limited${NC}"
    echo ""
fi

ISSUES_FOUND=0
WARNINGS_FOUND=0

# Check 1: Key directory exists
echo -n "1. Key directory exists... "
if [ -d "$KEY_DIR" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${YELLOW}⊘ SKIP (no encryption configured)${NC}"
    exit 0
fi

# Check 2: Key directory permissions
echo -n "2. Key directory permissions (should be 700)... "
DIR_PERMS=$(stat -f "%Lp" "$KEY_DIR" 2>/dev/null || stat -c "%a" "$KEY_DIR" 2>/dev/null)
if [ "$DIR_PERMS" = "700" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL (found: $DIR_PERMS)${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    echo -e "   ${YELLOW}Fix: sudo chmod 700 $KEY_DIR${NC}"
fi

# Check 3: Key directory ownership
echo -n "3. Key directory owned by root... "
DIR_OWNER=$(stat -f "%Su" "$KEY_DIR" 2>/dev/null || stat -c "%U" "$KEY_DIR" 2>/dev/null)
if [ "$DIR_OWNER" = "root" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL (owner: $DIR_OWNER)${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    echo -e "   ${YELLOW}Fix: sudo chown root:wheel $KEY_DIR${NC}"
fi

# Check 4: Key files exist
echo -n "4. Key files present... "
KEY_COUNT=$(ls -1 "$KEY_DIR"/*.key 2>/dev/null | wc -l | tr -d ' ')
if [ "$KEY_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS ($KEY_COUNT keys found)${NC}"
else
    echo -e "${YELLOW}⚠  WARNING (no .key files found)${NC}"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
fi

# Check 5-N: Individual key file security
KEY_NUM=5
for keyfile in "$KEY_DIR"/*.key 2>/dev/null; do
    if [ -f "$keyfile" ]; then
        KEYNAME=$(basename "$keyfile")
        echo ""
        echo -e "${BLUE}Checking: $KEYNAME${NC}"
        
        # Check permissions
        echo -n "  ${KEY_NUM}a. File permissions (should be 600)... "
        KEY_PERMS=$(stat -f "%Lp" "$keyfile" 2>/dev/null || stat -c "%a" "$keyfile" 2>/dev/null)
        if [ "$KEY_PERMS" = "600" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL (found: $KEY_PERMS)${NC}"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
            echo -e "     ${YELLOW}Fix: sudo chmod 600 $keyfile${NC}"
        fi
        
        # Check ownership
        echo -n "  ${KEY_NUM}b. File owned by root... "
        KEY_OWNER=$(stat -f "%Su" "$keyfile" 2>/dev/null || stat -c "%U" "$keyfile" 2>/dev/null)
        if [ "$KEY_OWNER" = "root" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL (owner: $KEY_OWNER)${NC}"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
            echo -e "     ${YELLOW}Fix: sudo chown root:wheel $keyfile${NC}"
        fi
        
        # Check if world-readable
        echo -n "  ${KEY_NUM}c. Not world-readable... "
        if [ -r "$keyfile" ]; then
            WORLD_READ=$(stat -f "%Sp" "$keyfile" 2>/dev/null | cut -c9)
            if [ "$WORLD_READ" = "-" ]; then
                echo -e "${GREEN}✓ PASS${NC}"
            else
                echo -e "${RED}✗ CRITICAL (world-readable!)${NC}"
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
                echo -e "     ${YELLOW}Fix: sudo chmod 600 $keyfile${NC}"
            fi
        else
            echo -e "${GREEN}✓ PASS${NC}"
        fi
        
        # Check key size
        echo -n "  ${KEY_NUM}d. Key size (should be 32 bytes)... "
        KEY_SIZE=$(stat -f "%z" "$keyfile" 2>/dev/null || stat -c "%s" "$keyfile" 2>/dev/null)
        if [ "$KEY_SIZE" = "32" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${YELLOW}⚠  WARNING (size: $KEY_SIZE bytes)${NC}"
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
        
        # Generate fingerprint
        echo -n "  ${KEY_NUM}e. Generate fingerprint... "
        FINGERPRINT=$(shasum -a 256 "$keyfile" 2>/dev/null | awk '{print $1}')
        if [ -n "$FINGERPRINT" ]; then
            echo -e "${GREEN}✓ ${FINGERPRINT:0:16}...${NC}"
        else
            echo -e "${YELLOW}⚠  Cannot generate${NC}"
        fi
        
        KEY_NUM=$((KEY_NUM + 1))
    fi
done

echo ""
echo -e "${BLUE}=========================================="
echo "Security Audit Summary"
echo -e "==========================================${NC}"
echo "Critical Issues: $ISSUES_FOUND"
echo "Warnings: $WARNINGS_FOUND"
echo ""

if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ All security checks passed!${NC}"
    echo "Your encryption keys are properly secured."
    exit 0
elif [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${YELLOW}⚠  Some warnings found, but no critical issues.${NC}"
    exit 0
else
    echo -e "${RED}✗ Critical security issues found!${NC}"
    echo ""
    echo "Please review and fix the issues listed above."
    echo "Run this script again after applying fixes."
    exit 1
fi
