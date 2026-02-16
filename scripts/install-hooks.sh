#!/bin/bash

###############################################################################
# Pre-commit Hook Setup
# 
# Purpose: Install pre-commit hooks for code quality checks
# Usage: ./scripts/install-hooks.sh
###############################################################################

set -e

echo "=========================================="
echo "Installing Git Pre-Commit Hooks"
echo "=========================================="
echo ""

# Get the repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook for macOS ZFS DAS
# Runs shellcheck on modified bash scripts

echo "Running pre-commit checks..."

# Get list of staged .sh files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' || true)

if [ -z "$STAGED_FILES" ]; then
    echo "No shell scripts to check"
    exit 0
fi

# Check if shellcheck is installed
if ! command -v shellcheck &>/dev/null; then
    echo "⚠️  WARNING: shellcheck not installed"
    echo "   Install with: brew install shellcheck"
    echo "   Skipping shellcheck for now..."
    exit 0
fi

# Run shellcheck on each file
ERRORS=0
for file in $STAGED_FILES; do
    echo "Checking $file..."
    if ! shellcheck "$file"; then
        ERRORS=$((ERRORS + 1))
    fi
done

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ ShellCheck found $ERRORS error(s)"
    echo "   Fix the issues or use 'git commit --no-verify' to skip"
    exit 1
fi

echo "✅ All checks passed!"
exit 0
EOF

# Make hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✓ Pre-commit hook installed at:"
echo "  $HOOKS_DIR/pre-commit"
echo ""
echo "The hook will run shellcheck on modified .sh files before each commit."
echo ""
echo "To bypass the hook temporarily, use:"
echo "  git commit --no-verify"
echo ""
echo "Installation complete!"
