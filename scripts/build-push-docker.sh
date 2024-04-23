#!/usr/bin/env bash

set -e 

QGIS_TYPE=$1
RELEASE_TYPE=$2
QGIS_VERSION=$3
UBUNTU_DIST=$4
DEFAULT_UBUNTU_DIST=$5

MAJOR_QGIS_VERSION=$(echo "${QGIS_VERSION}" | cut -d. -f1,2)

if [[ ${RELEASE_TYPE} =~ ^ltr$ ]]; then
  QGIS_UBUNTU_PPA='ubuntu-ltr'
else
  QGIS_UBUNTU_PPA='ubuntu'
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
echo "UBUNTU_DIST: ${UBUNTU_DIST}"
echo "DEFAULT_UBUNTU_DIST: ${DEFAULT_UBUNTU_DIST}"
echo "QGIS_UBUNTU_PPA: ${QGIS_UBUNTU_PPA}"

TAGS="${RELEASE_TYPE}-${UBUNTU_DIST} ${MAJOR_QGIS_VERSION}-${UBUNTU_DIST} ${QGIS_VERSION}-${UBUNTU_DIST}"
if [[ ${UBUNTU_DIST} == ${DEFAULT_UBUNTU_DIST} ]]; then
  TAGS="${RELEASE_TYPE} ${MAJOR_QGIS_VERSION} ${QGIS_VERSION} ${TAGS}"
fi
echo "TAGS: ${TAGS}"

ALL_TAGS=""
for TAG in ${TAGS}; do
  ALL_TAGS="${ALL_TAGS} --tag qgis/${REPO}:${TAG}"
done

docker buildx build --push --platform linux/amd64,linux/arm64 --build-arg ubuntu_dist=${UBUNTU_DIST} --build-arg repo=${QGIS_UBUNTU_PPA}  ${ALL_TAGS} -f ${QGIS_TYPE}/Dockerfile .

