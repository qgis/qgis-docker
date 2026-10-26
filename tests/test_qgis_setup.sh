#!/usr/bin/env bash
# Unit tests for qgis_setup.sh
# Run with: bash tests/test_qgis_setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETUP_SCRIPT="${REPO_DIR}/desktop/scripts/test_runner/qgis_setup.sh"

PASS=0
FAIL=0
TESTS_RUN=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc}"
        echo "    expected: '${expected}'"
        echo "    actual:   '${actual}'"
        FAIL=$((FAIL + 1))
    fi
}

assert_file_exists() {
    local desc="$1" path="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -e "$path" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — file not found: ${path}"
        FAIL=$((FAIL + 1))
    fi
}

assert_dir_exists() {
    local desc="$1" path="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -d "$path" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — directory not found: ${path}"
        FAIL=$((FAIL + 1))
    fi
}

assert_file_contains() {
    local desc="$1" path="$2" pattern="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "$pattern" "$path" 2>/dev/null; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — pattern '${pattern}' not found in ${path}"
        FAIL=$((FAIL + 1))
    fi
}

assert_symlink() {
    local desc="$1" path="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -L "$path" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — not a symlink: ${path}"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_code() {
    local desc="$1" expected="$2" actual="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — expected exit ${expected}, got ${actual}"
        FAIL=$((FAIL + 1))
    fi
}

# Create a temp root to simulate /root
setup_test_env() {
    TEST_ROOT=$(mktemp -d)
    export HOME="${TEST_ROOT}/root"
    mkdir -p "${HOME}"

    # Create a mock qgis binary that outputs version info
    MOCK_BIN="${TEST_ROOT}/bin"
    mkdir -p "${MOCK_BIN}"
    cat > "${MOCK_BIN}/qgis" << 'MOCK'
#!/bin/bash
echo "QGIS - 3.38.0-Gresketeer 'Sketeer' (sketeer)"
echo "QGIS is now loading..."
MOCK
    chmod +x "${MOCK_BIN}/qgis"

    # Create a mock perl
    cat > "${MOCK_BIN}/perl" << 'MOCK'
#!/bin/bash
# Simple perl replacement for the pattern used in qgis_setup.sh
while IFS= read -r line; do
    echo "$line" | sed -E 's/QGIS - ([0-9]+)\.([0-9]+).*/showTips\1\2=false/'
done
MOCK
    chmod +x "${MOCK_BIN}/perl"

    # Create mock qgis_startup.py at /usr/bin/ equivalent
    mkdir -p "${MOCK_BIN}"
    echo "# mock startup" > "${MOCK_BIN}/qgis_startup.py"

    export PATH="${MOCK_BIN}:${PATH}"

    # Create the adapted script that uses $HOME instead of /root
    ADAPTED_SCRIPT="${TEST_ROOT}/qgis_setup_adapted.sh"
    sed "s|/root/|${HOME}/|g; s|/usr/bin/qgis_startup.py|${MOCK_BIN}/qgis_startup.py|g" \
        "${SETUP_SCRIPT}" > "${ADAPTED_SCRIPT}"
    chmod +x "${ADAPTED_SCRIPT}"
}

cleanup_test_env() {
    rm -rf "${TEST_ROOT}"
}

# ─── Test 1: Basic setup without plugin ───────────────────────────

test_basic_setup_no_plugin() {
    echo "Test 1: Basic setup without plugin name"
    setup_test_env

    bash "${ADAPTED_SCRIPT}"

    CONF_DIR="${HOME}/.local/share/QGIS/QGIS3/profiles/default/QGIS"
    CONF_FILE="${CONF_DIR}/QGIS3.ini"
    PLUGIN_DIR="${HOME}/.local/share/QGIS/QGIS3/profiles/default/python/plugins"
    STARTUP_DIR="${HOME}/.local/share/QGIS/QGIS3"

    assert_dir_exists "Config directory created" "${CONF_DIR}"
    assert_file_exists "Config file created" "${CONF_FILE}"
    assert_dir_exists "Plugin directory created" "${PLUGIN_DIR}"
    assert_dir_exists "Startup directory created" "${STARTUP_DIR}"
    assert_file_exists "startup.py installed" "${STARTUP_DIR}/startup.py"
    assert_file_contains "Config has [qgis] section" "${CONF_FILE}" "\[qgis\]"
    assert_file_contains "Config has showTips disabled" "${CONF_FILE}" "showTips.*=false"
    assert_file_contains "Config has [migration] section" "${CONF_FILE}" "\[migration\]"
    assert_file_contains "Config has firstRunVersionFlag" "${CONF_FILE}" "firstRunVersionFlag=30500"
    # Should NOT have PythonPlugins section (no plugin specified)
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -q "PythonPlugins" "${CONF_FILE}" 2>/dev/null; then
        echo "  PASS: No PythonPlugins section without plugin"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: PythonPlugins section should not exist without plugin"
        FAIL=$((FAIL + 1))
    fi

    cleanup_test_env
}

# ─── Test 2: Setup with plugin name ──────────────────────────────

test_setup_with_plugin() {
    echo "Test 2: Setup with plugin name"
    setup_test_env

    # Create a fake plugin directory at /tests_directory/
    TESTS_DIR="${TEST_ROOT}/tests_directory"
    mkdir -p "${TESTS_DIR}/my_test_plugin"

    # Adapt the script to use our test /tests_directory
    sed -i.bak "s|/tests_directory/|${TESTS_DIR}/|g" "${ADAPTED_SCRIPT}"

    bash "${ADAPTED_SCRIPT}" my_test_plugin

    CONF_FILE="${HOME}/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini"
    PLUGIN_DIR="${HOME}/.local/share/QGIS/QGIS3/profiles/default/python/plugins"

    assert_file_contains "Config has [PythonPlugins]" "${CONF_FILE}" "\[PythonPlugins\]"
    assert_file_contains "Plugin enabled in config" "${CONF_FILE}" "my_test_plugin=true"
    assert_symlink "Plugin symlinked" "${PLUGIN_DIR}/my_test_plugin"

    cleanup_test_env
}

# ─── Test 3: Error when plugin directory missing ─────────────────

test_error_missing_plugin_dir() {
    echo "Test 3: Error when plugin directory is missing"
    setup_test_env

    # Point to nonexistent tests_directory
    sed -i.bak "s|/tests_directory/|${TEST_ROOT}/nonexistent/|g" "${ADAPTED_SCRIPT}"

    local exit_code=0
    bash "${ADAPTED_SCRIPT}" missing_plugin 2>/dev/null || exit_code=$?

    assert_exit_code "Exits with error for missing plugin dir" "1" "${exit_code}"

    cleanup_test_env
}

# ─── Test 4: Config file is recreated on re-run ─────────────────

test_config_recreated() {
    echo "Test 4: Config file is recreated on re-run"
    setup_test_env

    # First run
    bash "${ADAPTED_SCRIPT}"

    CONF_FILE="${HOME}/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini"

    # Add garbage to config file
    echo "garbage_data=true" >> "${CONF_FILE}"
    assert_file_contains "Garbage added" "${CONF_FILE}" "garbage_data"

    # Second run should recreate config
    bash "${ADAPTED_SCRIPT}"

    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -q "garbage_data" "${CONF_FILE}" 2>/dev/null; then
        echo "  PASS: Config file recreated (garbage removed)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: Config file should be recreated on re-run"
        FAIL=$((FAIL + 1))
    fi

    cleanup_test_env
}

# ─── Test 5: Plugin already installed (dir exists) ───────────────

test_plugin_already_installed() {
    echo "Test 5: Plugin already installed skips symlinking"
    setup_test_env

    PLUGIN_DIR="${HOME}/.local/share/QGIS/QGIS3/profiles/default/python/plugins"
    mkdir -p "${PLUGIN_DIR}/existing_plugin"

    TESTS_DIR="${TEST_ROOT}/tests_directory"
    mkdir -p "${TESTS_DIR}/existing_plugin"
    sed -i.bak "s|/tests_directory/|${TESTS_DIR}/|g" "${ADAPTED_SCRIPT}"

    bash "${ADAPTED_SCRIPT}" existing_plugin

    # Should NOT be a symlink since it already existed as a directory
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ ! -L "${PLUGIN_DIR}/existing_plugin" ]]; then
        echo "  PASS: Existing plugin dir not replaced with symlink"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: Existing plugin dir should not be replaced"
        FAIL=$((FAIL + 1))
    fi

    cleanup_test_env
}

# ─── Run all tests ───────────────────────────────────────────────

echo "=== qgis_setup.sh Unit Tests ==="
echo ""

test_basic_setup_no_plugin
echo ""
test_setup_with_plugin
echo ""
test_error_missing_plugin_dir
echo ""
test_config_recreated
echo ""
test_plugin_already_installed

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed, ${TESTS_RUN} total ==="

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
exit 0
