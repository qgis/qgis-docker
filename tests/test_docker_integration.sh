#!/usr/bin/env bash
# Docker integration tests for the test runner scripts.
# Builds the desktop Docker image and verifies that the test runner scripts
# are correctly installed and functional.
#
# Usage:  bash tests/test_docker_integration.sh
# Requires: docker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_TAG="qgis-test-runner-integration"
CONTAINER_NAME="qgis-test-runner-integration-$$"

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

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$haystack" | grep -q "$needle"; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — '${needle}' not found in output"
        FAIL=$((FAIL + 1))
    fi
}

cleanup() {
    echo "Cleaning up..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
}
trap cleanup EXIT

# ─── Build the image ─────────────────────────────────────────────

echo "=== Docker Integration Tests ==="
echo ""
echo "Building desktop Docker image..."
docker build -t "${IMAGE_TAG}" \
    --build-arg repo=ubuntu \
    -f "${REPO_DIR}/desktop/Dockerfile" \
    "${REPO_DIR}" 2>&1 | tail -5

echo ""

# ─── Test 1: Scripts exist and are executable ────────────────────

echo "Test 1: Scripts exist at /usr/bin/ and are executable"

for script in qgis_setup.sh qgis_startup.py qgis_testrunner.py qgis_testrunner.sh; do
    result=$(docker run --rm "${IMAGE_TAG}" test -f "/usr/bin/${script}" && echo "exists" || echo "missing")
    assert_eq "${script} exists" "exists" "${result}"
done

for script in qgis_setup.sh qgis_testrunner.sh; do
    result=$(docker run --rm "${IMAGE_TAG}" test -x "/usr/bin/${script}" && echo "executable" || echo "not-executable")
    assert_eq "${script} is executable" "executable" "${result}"
done

echo ""

# ─── Test 2: which finds the scripts ────────────────────────────

echo "Test 2: which finds qgis_setup.sh"
which_output=$(docker run --rm "${IMAGE_TAG}" which qgis_setup.sh)
assert_eq "which qgis_setup.sh" "/usr/bin/qgis_setup.sh" "${which_output}"

echo ""

# ─── Test 3: qgis_setup.sh runs without plugin ──────────────────

echo "Test 3: qgis_setup.sh creates config directories (no plugin)"
docker run --rm --name "${CONTAINER_NAME}" \
    -e QT_QPA_PLATFORM=offscreen \
    "${IMAGE_TAG}" \
    bash -c '
        qgis_setup.sh && \
        test -d "/root/.local/share/QGIS/QGIS3/profiles/default/QGIS" && echo "CONF_DIR_OK" && \
        test -f "/root/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini" && echo "CONF_FILE_OK" && \
        test -d "/root/.local/share/QGIS/QGIS3/profiles/default/python/plugins" && echo "PLUGIN_DIR_OK" && \
        test -f "/root/.local/share/QGIS/QGIS3/startup.py" && echo "STARTUP_OK" && \
        grep -q "\[migration\]" "/root/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini" && echo "MIGRATION_OK"
    ' > /tmp/setup_output_$$ 2>&1

output=$(cat /tmp/setup_output_$$)
rm -f /tmp/setup_output_$$

assert_contains "Config directory created" "${output}" "CONF_DIR_OK"
assert_contains "Config file created" "${output}" "CONF_FILE_OK"
assert_contains "Plugin directory created" "${output}" "PLUGIN_DIR_OK"
assert_contains "startup.py installed" "${output}" "STARTUP_OK"
assert_contains "Migration section written" "${output}" "MIGRATION_OK"

echo ""

# ─── Test 4: qgis_setup.sh with a plugin ────────────────────────

echo "Test 4: qgis_setup.sh sets up a plugin"

# Create a temp plugin directory
PLUGIN_TMP=$(mktemp -d)
mkdir -p "${PLUGIN_TMP}/my_test_plugin"
echo "# test plugin init" > "${PLUGIN_TMP}/my_test_plugin/__init__.py"

docker run --rm --name "${CONTAINER_NAME}" \
    -v "${PLUGIN_TMP}:/tests_directory:ro" \
    -e QT_QPA_PLATFORM=offscreen \
    "${IMAGE_TAG}" \
    bash -c '
        qgis_setup.sh my_test_plugin && \
        test -L "/root/.local/share/QGIS/QGIS3/profiles/default/python/plugins/my_test_plugin" && echo "SYMLINK_OK" && \
        grep -q "PythonPlugins" "/root/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini" && echo "PLUGINS_SECTION_OK" && \
        grep -q "my_test_plugin=true" "/root/.local/share/QGIS/QGIS3/profiles/default/QGIS/QGIS3.ini" && echo "PLUGIN_ENABLED_OK"
    ' > /tmp/plugin_output_$$ 2>&1

output=$(cat /tmp/plugin_output_$$)
rm -f /tmp/plugin_output_$$
rm -rf "${PLUGIN_TMP}"

assert_contains "Plugin symlinked" "${output}" "SYMLINK_OK"
assert_contains "PythonPlugins section exists" "${output}" "PLUGINS_SECTION_OK"
assert_contains "Plugin enabled in config" "${output}" "PLUGIN_ENABLED_OK"

echo ""

# ─── Test 5: qgis_setup.sh fails for missing plugin ─────────────

echo "Test 5: qgis_setup.sh fails for missing plugin"
exit_code=0
docker run --rm "${IMAGE_TAG}" \
    bash -c 'qgis_setup.sh nonexistent_plugin' 2>/dev/null || exit_code=$?

TESTS_RUN=$((TESTS_RUN + 1))
if [[ "${exit_code}" -ne 0 ]]; then
    echo "  PASS: Exits with error for missing plugin"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Should exit non-zero for missing plugin"
    FAIL=$((FAIL + 1))
fi

echo ""

# ─── Test 6: PYTHONPATH is set ───────────────────────────────────

echo "Test 6: PYTHONPATH is set correctly"
pythonpath=$(docker run --rm "${IMAGE_TAG}" bash -c 'echo $PYTHONPATH')
assert_contains "PYTHONPATH includes qgis python" "${pythonpath}" "/usr/share/qgis/python"

echo ""

# ─── Summary ─────────────────────────────────────────────────────

echo "=== Results: ${PASS} passed, ${FAIL} failed, ${TESTS_RUN} total ==="

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
exit 0
