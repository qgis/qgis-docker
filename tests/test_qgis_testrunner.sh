#!/usr/bin/env bash
# Unit tests for qgis_testrunner.sh
# Tests the output parsing logic without needing a real QGIS instance.
# Run with: bash tests/test_qgis_testrunner.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNNER_SCRIPT="${REPO_DIR}/desktop/scripts/test_runner/qgis_testrunner.sh"

PASS=0
FAIL=0
TESTS_RUN=0

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

# Create a temporary directory for test setup
setup_test_env() {
    TEST_ROOT=$(mktemp -d)
    MOCK_BIN="${TEST_ROOT}/bin"
    mkdir -p "${MOCK_BIN}"

    # Create adapted runner script that uses our mock paths
    ADAPTED_SCRIPT="${TEST_ROOT}/qgis_testrunner.sh"
    cp "${RUNNER_SCRIPT}" "${ADAPTED_SCRIPT}"
    chmod +x "${ADAPTED_SCRIPT}"
}

cleanup_test_env() {
    rm -rf "${TEST_ROOT}"
}

# Create a mock QGIS that produces specific output
create_mock_qgis() {
    local output="$1"
    cat > "${MOCK_BIN}/qgis" << MOCK
#!/bin/bash
cat << 'OUTPUT'
${output}
OUTPUT
MOCK
    chmod +x "${MOCK_BIN}/qgis"
    # Also create mock unbuffer that just passes through
    cat > "${MOCK_BIN}/unbuffer" << 'MOCK'
#!/bin/bash
# Skip the first few args (qgis --version-migration --nologo --code runner.py)
# and just exec the command
exec "$@"
MOCK
    chmod +x "${MOCK_BIN}/unbuffer"
}

# ─── Test 1: Passing tests ───────────────────────────────────────

test_passing_output() {
    echo "Test 1: Passing test output gives exit 0"
    setup_test_env

    create_mock_qgis "QGIS Test Runner Inside - starting the tests ...
Ran 5 tests in 0.123s

OK"

    local exit_code=0
    QGIS_BUILD_PATH="${MOCK_BIN}/qgis" \
    TEST_RUNNER_PATH="/dev/null" \
    PATH="${MOCK_BIN}:${PATH}" \
        bash "${ADAPTED_SCRIPT}" "my_module.tests" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "Passing tests exit 0" "0" "${exit_code}"
    cleanup_test_env
}

# ─── Test 2: Failing tests ──────────────────────────────────────

test_failing_output() {
    echo "Test 2: Failing test output gives exit 1"
    setup_test_env

    create_mock_qgis "QGIS Test Runner Inside - starting the tests ...
Ran 3 tests in 0.456s

FAILED (failures=2)"

    local exit_code=0
    QGIS_BUILD_PATH="${MOCK_BIN}/qgis" \
    TEST_RUNNER_PATH="/dev/null" \
    PATH="${MOCK_BIN}:${PATH}" \
        bash "${ADAPTED_SCRIPT}" "my_module.tests" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "Failing tests exit 1" "1" "${exit_code}"
    cleanup_test_env
}

# ─── Test 3: Empty output ───────────────────────────────────────

test_empty_output() {
    echo "Test 3: Empty output gives exit 1"
    setup_test_env

    create_mock_qgis ""

    local exit_code=0
    QGIS_BUILD_PATH="${MOCK_BIN}/qgis" \
    TEST_RUNNER_PATH="/dev/null" \
    PATH="${MOCK_BIN}:${PATH}" \
        bash "${ADAPTED_SCRIPT}" "my_module.tests" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "Empty output exits 1" "1" "${exit_code}"
    cleanup_test_env
}

# ─── Test 4: QGIS crash/signal ──────────────────────────────────

test_crash_output() {
    echo "Test 4: QGIS crash/signal output gives exit 1"
    setup_test_env

    create_mock_qgis "QGIS Test Runner Inside - starting the tests ...
QGIS died on signal 11
Ran 2 tests in 0.001s

OK"

    local exit_code=0
    QGIS_BUILD_PATH="${MOCK_BIN}/qgis" \
    TEST_RUNNER_PATH="/dev/null" \
    PATH="${MOCK_BIN}:${PATH}" \
        bash "${ADAPTED_SCRIPT}" "my_module.tests" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "QGIS crash exits 1" "1" "${exit_code}"
    cleanup_test_env
}

# ─── Test 5: Output with OK but no Ran line ──────────────────────

test_ok_without_ran() {
    echo "Test 5: OK without 'Ran' line gives exit 1"
    setup_test_env

    create_mock_qgis "Some random output
OK but this is not a real test result"

    local exit_code=0
    QGIS_BUILD_PATH="${MOCK_BIN}/qgis" \
    TEST_RUNNER_PATH="/dev/null" \
    PATH="${MOCK_BIN}:${PATH}" \
        bash "${ADAPTED_SCRIPT}" "my_module.tests" > /dev/null 2>&1 || exit_code=$?

    assert_exit_code "OK without Ran exits 1" "1" "${exit_code}"
    cleanup_test_env
}

# ─── Run all tests ───────────────────────────────────────────────

echo "=== qgis_testrunner.sh Unit Tests ==="
echo ""

test_passing_output
echo ""
test_failing_output
echo ""
test_empty_output
echo ""
test_crash_output
echo ""
test_ok_without_ran

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed, ${TESTS_RUN} total ==="

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
exit 0
