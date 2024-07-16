#!/usr/bin/env bash

set -e

QGIS_TYPE=$1
RELEASE_TYPE=$2
QGIS_VERSION=$3
OS=$4
OS_RELEASE=$5
DEFAULT_OS_RELEASE=$6

MAJOR_QGIS_VERSION=$(echo "${QGIS_VERSION}" | cut -d. -f1,2)

if [[ ${RELEASE_TYPE} =~ ^ltr$ ]]; then
  QGIS_PPA="${OS}-ltr"
else
  QGIS_PPA="${OS}"
fi

if [[ ${QGIS_TYPE} =~ ^server$ ]]; then
  REPO='qgis-server'
else
  REPO='qgis'
fi


echo "Building QGIS Server Docker image:"
echo "QGIS_TYPE: ${QGIS_TYPE}"
echo "RELEASE_TYPE: ${RELEASE_TYPE}"
echo "QGIS_VERSION: ${QGIS_VERSION}"
echo "MAJOR_QGIS_VERSION: ${MAJOR_QGIS_VERSION}"
echo "OS: ${OS}"
echo "OS_RELEASE: ${OS_RELEASE}"
echo "DEFAULT_OS_RELEASE: ${DEFAULT_OS_RELEASE}"
echo "QGIS_PPA: ${QGIS_PPA}"

TAGS="${RELEASE_TYPE}-${OS_RELEASE} ${MAJOR_QGIS_VERSION}-${OS_RELEASE} ${QGIS_VERSION}-${OS_RELEASE}"
if [[ ${OS_RELEASE} == ${DEFAULT_OS_RELEASE} ]]; then
  TAGS="${RELEASE_TYPE} ${MAJOR_QGIS_VERSION} ${QGIS_VERSION} ${TAGS}"
fi
echo "TAGS: ${TAGS}"

ALL_TAGS=""
for TAG in ${TAGS}; do
  ALL_TAGS="${ALL_TAGS} --tag qgis/${REPO}:${TAG}"
done

docker buildx build --push --platform linux/amd64,linux/arm64 --build-arg os=${OS} --build-arg release=${OS_RELEASE} --build-arg repo=${QGIS_PPA}  ${ALL_TAGS} -f ${QGIS_TYPE}/Dockerfile .
