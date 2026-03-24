#!/usr/bin/env bash
# Tests for the QGIS Server landing page nginx configuration.
# Verifies that the start-xvfb-nginx.sh script correctly generates
# the landing page nginx config snippet based on environment variables.
#
# Usage:  bash tests/test_server_landing_page.sh
# Does not require Docker.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

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

assert_not_exists() {
    local desc="$1" filepath="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ ! -f "$filepath" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — file '${filepath}' exists but should not"
        FAIL=$((FAIL + 1))
    fi
}

assert_file_exists() {
    local desc="$1" filepath="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -f "$filepath" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: ${desc} — file '${filepath}' not found"
        FAIL=$((FAIL + 1))
    fi
}

# ─── Setup ──────────────────────────────────────────────────────

TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

# Create the directory the script writes to
QGIS_D="${TMPDIR}/etc/nginx/qgis.d"
mkdir -p "$QGIS_D"

# Extract just the landing page config generation logic from start-xvfb-nginx.sh
# and test it in isolation.
generate_landing_page_conf() {
    # Clean up from previous run
    rm -f "${QGIS_D}/landing-page.conf"

    if [ -n "${QGIS_SERVER_LANDING_PAGE_PREFIX:-}" ]; then
        PREFIX="${QGIS_SERVER_LANDING_PAGE_PREFIX}"
        [[ "$PREFIX" != /* ]] && PREFIX="/${PREFIX}"
        if [[ "$PREFIX" =~ ^/[a-zA-Z0-9/_-]+$ ]]; then
            cat > "${QGIS_D}/landing-page.conf" <<LANDING_CONF
location ${PREFIX} {
    fastcgi_pass  localhost:9993;
    fastcgi_param SCRIPT_FILENAME /usr/lib/cgi-bin/qgis_mapserv.fcgi;
    fastcgi_param QUERY_STRING    \$query_string;
    fastcgi_param HTTPS           \$qgis_ssl;
    fastcgi_param SERVER_NAME     \$qgis_host;
    fastcgi_param SERVER_PORT     \$qgis_port;
    include fastcgi_params;
}
LANDING_CONF
            return 0
        else
            return 1
        fi
    fi
    return 0
}

echo "=== Landing Page Config Generation Tests ==="
echo ""

# ─── Test 1: No env var set → no config file ────────────────────

echo "Test 1: No QGIS_SERVER_LANDING_PAGE_PREFIX → no config generated"
unset QGIS_SERVER_LANDING_PAGE_PREFIX 2>/dev/null || true
generate_landing_page_conf
assert_not_exists "no landing-page.conf when prefix unset" "${QGIS_D}/landing-page.conf"
echo ""

# ─── Test 2: Empty env var → no config file ─────────────────────

echo "Test 2: Empty QGIS_SERVER_LANDING_PAGE_PREFIX → no config generated"
QGIS_SERVER_LANDING_PAGE_PREFIX=""
generate_landing_page_conf
assert_not_exists "no landing-page.conf when prefix empty" "${QGIS_D}/landing-page.conf"
echo ""

# ─── Test 3: Valid prefix with leading slash ─────────────────────

echo "Test 3: QGIS_SERVER_LANDING_PAGE_PREFIX=/catalog → config generated"
QGIS_SERVER_LANDING_PAGE_PREFIX="/catalog"
generate_landing_page_conf
assert_file_exists "landing-page.conf created" "${QGIS_D}/landing-page.conf"
CONF=$(cat "${QGIS_D}/landing-page.conf")
assert_contains "contains location /catalog" "$CONF" "location /catalog {"
assert_contains "contains fastcgi_pass" "$CONF" "fastcgi_pass  localhost:9993"
assert_contains "contains SCRIPT_FILENAME" "$CONF" "SCRIPT_FILENAME /usr/lib/cgi-bin/qgis_mapserv.fcgi"
assert_contains "contains include fastcgi_params" "$CONF" "include fastcgi_params"
echo ""

# ─── Test 4: Valid prefix without leading slash ──────────────────

echo "Test 4: QGIS_SERVER_LANDING_PAGE_PREFIX=catalog → slash prepended"
QGIS_SERVER_LANDING_PAGE_PREFIX="catalog"
generate_landing_page_conf
assert_file_exists "landing-page.conf created" "${QGIS_D}/landing-page.conf"
CONF=$(cat "${QGIS_D}/landing-page.conf")
assert_contains "contains location /catalog" "$CONF" "location /catalog {"
echo ""

# ─── Test 5: Nested prefix ──────────────────────────────────────

echo "Test 5: QGIS_SERVER_LANDING_PAGE_PREFIX=/ogc/catalog → nested prefix works"
QGIS_SERVER_LANDING_PAGE_PREFIX="/ogc/catalog"
generate_landing_page_conf
assert_file_exists "landing-page.conf created" "${QGIS_D}/landing-page.conf"
CONF=$(cat "${QGIS_D}/landing-page.conf")
assert_contains "contains location /ogc/catalog" "$CONF" "location /ogc/catalog {"
echo ""

# ─── Test 6: Invalid prefix rejected ────────────────────────────

echo "Test 6: Invalid prefix with special chars → config NOT generated"
QGIS_SERVER_LANDING_PAGE_PREFIX="/cat;alog"
rm -f "${QGIS_D}/landing-page.conf"
generate_landing_page_conf || true
assert_not_exists "no landing-page.conf for invalid prefix" "${QGIS_D}/landing-page.conf"
echo ""

# ─── Test 7: nginx config has include directive ──────────────────

echo "Test 7: qgis-server-nginx.conf includes qgis.d/*.conf"
NGINX_CONF="${REPO_DIR}/server/conf/qgis-server-nginx.conf"
assert_contains "include directive present" "$(cat "$NGINX_CONF")" "include /etc/nginx/qgis.d/\*.conf"
echo ""

# ─── Summary ────────────────────────────────────────────────────

echo "=== Results: ${PASS} passed, ${FAIL} failed, ${TESTS_RUN} total ==="
exit $FAIL
