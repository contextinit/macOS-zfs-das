# Testing Documentation

## Overview

This directory contains the automated test suite for the macOS ZFS DAS project. Tests ensure code quality, script correctness, and system integration.

## Test Structure

```
tests/
├── run-all-tests.sh          # Master test runner
├── test-shellcheck.sh         # ShellCheck linting tests
├── test-scripts.sh            # Script validation tests
├── test-config-integration.sh # Config system integration tests
└── README.md                  # This file
```

## Running Tests

### Run All Tests

```bash
cd /path/to/macos-zfs-das
./tests/run-all-tests.sh
```

### Run Individual Test Suites

```bash
# ShellCheck linting
./tests/test-shellcheck.sh

# Script validation
./tests/test-scripts.sh

# Config integration
./tests/test-config-integration.sh
```

## Test Suites

### 1. ShellCheck Linting (`test-shellcheck.sh`)

**Purpose:** Validates bash script syntax and best practices

**Checks:**
- Syntax errors
- Quoting issues
- Unused variables
- Potential bugs
- Style issues

**Scripts Tested:**
- `scripts/zfs-automount.sh`
- `scripts/zfs-maintenance.sh`
- `scripts/setup-timemachine.sh`
- `scripts/create-pool.sh`
- `scripts/setup-encryption.sh`
- `scripts/setup-monitoring.sh`
- `swiftbar/zfs-monitor.30s.sh`
- `swiftbar/zfs-advanced.30s.sh`

**Requirements:**
- ShellCheck installed (`brew install shellcheck`)

---

### 2. Script Validation (`test-scripts.sh`)

**Purpose:** Validates script structure and basic functionality

**Tests:**
1. All installation scripts exist
2. All scripts are executable
3. All scripts have proper shebang (`#!/bin/bash` on line 1)
4. All scripts have valid bash syntax
5. Critical scripts use full paths for commands
6. SwiftBar plugins exist

**What It Checks:**
- File existence
- Executable permissions
- Shebang correctness
- Syntax validity
- Path safety

---

### 3. Config Integration (`test-config-integration.sh`)

**Purpose:** Verifies centralized configuration system works correctly

**Tests:**
1. Config file exists
2. Config file has valid syntax
3. Scripts contain config sourcing code
4. No hardcoded pool names (scripts use `$POOL_NAME` variable)
5. Config has all required variables

**Required Variables Checked:**
- `POOL_NAME`
- `ZFS_BIN_PATH`
- `ENABLE_TIME_MACHINE`

---

## Continuous Integration

### GitHub Actions

Tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

**Workflow:** `.github/workflows/ci.yml`

**Jobs:**
1. **shellcheck** - Runs ShellCheck linting
2. **script-validation** - Validates script structure
3. **config-integration** - Tests config system
4. **full-test-suite** - Runs all tests together

**View Results:**
- Check the "Actions" tab on GitHub
- Green checkmark = all tests passed
- Red X = some tests failed

---

## Pre-Commit Hooks

### Installation

```bash
./scripts/install-hooks.sh
```

### What It Does

Before each commit, the pre-commit hook:
1. Finds all staged `.sh` files
2. Runs shellcheck on each file
3. Blocks commit if errors found
4. Shows detailed error messages

### Bypass Hook

To commit without running checks (not recommended):

```bash
git commit --no-verify
```

---

## Configuration

### ShellCheck Configuration

File: `.shellcheckrc`

```bash
# Disabled checks
disable=SC1090  # Can't follow non-constant source
disable=SC2148  # Shebang tips
disable=SC2312  # Separate invocation tips

# Shell dialect
shell=bash

# Severity
severity=style
```

### Customizing Tests

Edit test scripts to add/modify checks:

```bash
# Add new test
echo -n "Test X: Description... "
if [ condition ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi
```

---

## Test Results Format

```
==========================================
Test Name
==========================================

Test 1: Description... ✓ PASS
Test 2: Description... ✗ FAIL
Test 3: Description... ✓ PASS

==========================================
Test Results
==========================================
Total tests: 3
Passed: 2
Failed: 1

✗ Some tests failed
```

---

## Troubleshooting

### ShellCheck Not Installed

```bash
# macOS
brew install shellcheck

# Linux
apt-get install shellcheck
```

### Tests Not Executable

```bash
chmod +x tests/*.sh
```

### Syntax Errors in Scripts

Run shellcheck manually to see details:

```bash
shellcheck scripts/script-name.sh
```

### Config Tests Failing

Verify config file exists and has proper format:

```bash
# Check syntax
bash -n configs/zfs-das.conf

# Verify variables
grep "POOL_NAME=" configs/zfs-das.conf
```

---

## Adding New Tests

### 1. Create Test Script

```bash
#!/bin/bash
# New test script

set -e
# ... test code ...
```

### 2. Add to Test Runner

Edit `run-all-tests.sh`:

```bash
run_test_suite "$SCRIPT_DIR/test-new-feature.sh" "New Feature Tests"
```

### 3. Update CI Workflow

Add job to `.github/workflows/ci.yml`:

```yaml
new-feature-tests:
  name: New Feature Tests
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - run: ./tests/test-new-feature.sh
```

---

## Test Coverage

### Current Coverage

- ✅ **ShellCheck Linting:** 100% of bash scripts
- ✅ **Script Validation:** All scripts checked for structure
- ✅ **Config Integration:** Core functionality tested
- ⚠️ **Functional Tests:** Not yet implemented (requires ZFS)

### Future Test Plans

1. **Mock ZFS Tests**
   - Simulate zpool/zfs commands
   - Test error handling paths
   - Verify retry logic

2. **Integration Tests**
   - Create test pool with loopback devices
   - Test full mount/unmount cycle
   - Verify encryption key handling

3. **Performance Tests**
   - Measure script execution time
   - Test with large pools
   - Monitor memory usage

---

## Best Practices

1. **Run tests before committing**
   ```bash
   ./tests/run-all-tests.sh
   ```

2. **Fix shellcheck warnings**
   - All warnings should be addressed
   - Document any disabled checks
   - Add comments for complex code

3. **Keep tests fast**
   - Tests should complete in < 30 seconds
   - Use mocks for slow operations
   - Parallelize where possible

4. **Write clear test names**
   - Good: `Test 5: Scripts use full paths`
   - Bad: `Test 5: Paths`

5. **Update tests with code changes**
   - Add tests for new features
   - Update tests when fixing bugs
   - Keep test coverage high

---

## Contributing

When adding new scripts:

1. Ensure script passes shellcheck
2. Add script to appropriate test file
3. Update test count expectations
4. Run full test suite before PR
5. Update this documentation if needed

---

## Resources

- [ShellCheck Documentation](https://github.com/koalaman/shellcheck/wiki)
- [Bash Best Practices](https://github.com/bahamas10/bash-style-guide)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Git Hooks Guide](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
