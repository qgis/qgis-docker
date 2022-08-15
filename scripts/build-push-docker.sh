#!/usr/bin/env bash

set -e 

RELEASE_TYPE=$1
QGIS_VERSION=$2
UBUNTU_DIST=$3

MAJOR_QGIS_VERSION=$(echo "${QGIS_VERSION}" | cut -d. -f1,2)

if [[ ${RELEASE_TYPE} =~ ^ltr$ ]]; then
  QGIS_UBUNTU_PPA='ubuntu-ltr'
else
  QGIS_UBUNTU_PPA='ubuntu'
fi

echo "Building QGIS Server Docker image:"
echo "RELEASE_TYPE: ${RELEASE_TYPE}"
echo "QGIS_VERSION: ${QGIS_VERSION}"
echo "MAJOR_QGIS_VERSION: ${MAJOR_QGIS_VERSION}"
echo "UBUNTU_DIST: ${UBUNTU_DIST}"
echo "QGIS_UBUNTU_PPA: ${QGIS_UBUNTU_PPA}"

for TAG in "${RELEASE_TYPE}" "${MAJOR_QGIS_VERSION}" "${QGIS_VERSION}"; do
  docker buildx build --push --platform linux/amd64,linux/arm64 --build-arg ubuntu_dist=${UBUNTU_DIST} --build-arg repo=${QGIS_UBUNTU_PPA} -t opengisch/qgis-server:${TAG} .
done

