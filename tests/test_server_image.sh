#!/usr/bin/env bash
# Functional tests of a QGIS Server image, shared by the qgis-server and qgis-server-slim images:
# OGC services, project routes, reverse proxy headers, landing page, non-root user, CORS and Python plugins.
#
# Usage:  bash tests/test_server_image.sh IMAGE
# Requires: docker, curl and a free port 8010

set -euo pipefail

IMAGE=$1
TEST_DIR="$(cd "$(dirname "$0")/../server/test" && pwd)"
URL=http://localhost:8010
WMS_CAPABILITIES="service=WMS&request=GetCapabilities"
CONTAINER=""

stop() {
    if [[ -n ${CONTAINER} ]]; then
        docker rm -f "${CONTAINER}" >/dev/null
        CONTAINER=""
    fi
}

cleanup() {
    local STATUS=$?
    if [[ ${STATUS} -ne 0 && -n ${CONTAINER} ]]; then
        echo "FAILED, logs of ${CONTAINER}:"
        docker logs "${CONTAINER}" 2>&1 | tail -50
    fi
    stop
}
trap cleanup EXIT

# Runs the image with the given options and waits until QGIS Server answers behind Nginx
start() {
    stop
    CONTAINER=qgis-server-test-$1
    shift
    echo "# ${CONTAINER}"
    docker run -d --name "${CONTAINER}" -p 8010:80 "$@" "${IMAGE}" >/dev/null
    for _ in $(seq 60); do
        # Nginx answers 502 until QGIS Server listens
        case $(curl -s -o /dev/null -w '%{http_code}' "${URL}/ows/") in
            000 | 502) sleep 1 ;;
            *) return 0 ;;
        esac
    done
    echo "QGIS Server did not start"
    return 1
}

start default -v "${TEST_DIR}/data:/io/data"

echo "WMS GetCapabilities"
[[ $(curl -sf "${URL}/ogc/test_project?${WMS_CAPABILITIES}") == *'<WMS_Capabilities'* ]]

echo "WMS GetMap"
[[ $(curl -sf -o /dev/null -w '%{content_type}' \
    "${URL}/ogc/test_project?service=WMS&version=1.3.0&request=GetMap&layers=layer&crs=EPSG:4326&bbox=-90,-180,90,180&width=200&height=100&format=image/png") \
    == image/png* ]]

echo "OGC API with MAP"
[[ $(curl -sf "${URL}/ogcapi/collections.json?MAP=/io/data/test_project/test_project.qgs") == *'"collections"'* ]]

echo "OGC API links of /ogc/ projects keep the route, without the project file"
COLLECTIONS=$(curl -sf "${URL}/ogc/test_project/ogcapi/collections.json")
[[ ${COLLECTIONS} == *'"http://localhost:8010/ogc/test_project/ogcapi/collections'* && ${COLLECTIONS} != *map=* ]]

echo "Links follow the reverse proxy headers, including the path prefix"
PROXY_HEADERS=(-H 'X-Forwarded-Host: example.com' -H 'X-Forwarded-Proto: https' -H 'X-Forwarded-Prefix: /qgis/')
[[ $(curl -s "${PROXY_HEADERS[@]}" "${URL}/ogc/test_project?${WMS_CAPABILITIES}") \
    == *'"https://example.com/qgis/ogc/test_project?'* ]]
[[ $(curl -s "${PROXY_HEADERS[@]}" "${URL}/ogcapi/collections.json?MAP=/io/data/test_project/test_project.qgs") \
    == *'"https://example.com:8010/qgis/ogcapi/collections'* ]]

echo "CORS is disabled by default"
HEADERS=$(curl -s -D - -o /dev/null "${URL}/ogc/test_project?${WMS_CAPABILITIES}")
[[ ${HEADERS,,} != *access-control-allow-origin* ]]

# mount the parent folder to get a nested project: /io/data/data/test_project/test_project.qgs
start project-paths -v "${TEST_DIR}:/io/data"

for PROJECT in data/test_project data/test_project/ data/test_project/test_project.qgs; do
    echo "Project path ${PROJECT}"
    [[ $(curl -sf "${URL}/ogc/${PROJECT}?${WMS_CAPABILITIES}") == *'<WMS_Capabilities'* ]]
    [[ $(curl -sf "${URL}/ogc/${PROJECT%/}/ogcapi/collections.json") == *'"collections"'* ]]
done

start landing-page -v "${TEST_DIR}/data:/io/data" \
    -e QGIS_SERVER_LANDING_PAGE_PREFIX=/catalog \
    -e QGIS_SERVER_LANDING_PAGE_PROJECTS_DIRECTORIES=/io/data/test_project

echo "Landing page Nginx configuration"
docker exec "${CONTAINER}" test -f /etc/nginx/qgis.d/landing-page.conf

echo "Landing page lists the test project"
[[ $(curl -s -o /dev/null -w '%{http_code}' "${URL}/catalog/") -ne 404 ]]
grep -Eq '"projects_count": ?1' <<<"$(curl -sf "${URL}/catalog/index.json")"

echo "Landing page web app"
APP_JS=$(curl -sf "${URL}/catalog/index.html" | grep -o 'js/app\.[0-9a-f]*\.js')
[[ $(curl -sf -o /dev/null -w '%{content_type}' "${URL}/catalog/${APP_JS}") == *javascript* ]]

start non-root --user 12345 -v "${TEST_DIR}/data:/io/data" -e QGIS_SERVER_LANDING_PAGE_PREFIX=/catalog

echo "Non-root user"
[[ $(curl -sf "${URL}/ogc/test_project?${WMS_CAPABILITIES}") == *'<WMS_Capabilities'* ]]
[[ $(curl -sf "${URL}/ogcapi/collections.json?MAP=/io/data/test_project/test_project.qgs") == *'"collections"'* ]]
docker exec "${CONTAINER}" test -f /etc/nginx/qgis.d/landing-page.conf

start cors -v "${TEST_DIR}/data:/io/data" -e NGINX_CORS_ALLOW_ORIGIN=https://example.com

echo "CORS headers"
HEADERS=$(curl -s -D - -o /dev/null "${URL}/ogc/test_project?${WMS_CAPABILITIES}")
[[ ${HEADERS,,} == *'access-control-allow-origin: https://example.com'* ]]

echo "Preflight requests are answered by Nginx"
[[ $(curl -s -o /dev/null -w '%{http_code}' -X OPTIONS "${URL}/ogc/test_project") -eq 204 ]]

start python-plugins -v "${TEST_DIR}/data:/io/data" -v "${TEST_DIR}/plugins:/io/plugins"

echo "Python server plugins"
HEADERS=$(curl -s -D - -o /dev/null "${URL}/ogc/test_project?${WMS_CAPABILITIES}")
[[ ${HEADERS,,} == *'x-qgis-test-plugin: loaded'* ]]

echo "All server tests passed"
