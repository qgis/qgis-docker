#!/usr/bin/env bash

VERSION_CHECK=$1
VERSION_INSTALLED=$(apt-cache show qgis | grep Version | cut -d' ' -f2 | cut -d. -f1,2 )

if [[ ${VERSION_CHECK} == ${VERSION_INSTALLED} ]]; then
  echo "version check ok: ${VERSION_INSTALLED}"
  exit 0
fi

echo "version mismatch!"
echo "installed: ${VERSION_INSTALLED}"
echo "check: ${VERSION_CHECK}"
exit 1
