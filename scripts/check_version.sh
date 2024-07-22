#!/usr/bin/env bash

VERSION_CHECK=$1
VERSION_INSTALLED=$(apt list --installed qgis | grep installed | cut -d: -f2 | cut -d\+ -f1)

if [[ ${VERSION_CHECK} == 'master' ]]; then
  echo "installed: ${VERSION_INSTALLED}"
  exit 0
fi

if [[ ${VERSION_INSTALLED} =~ ^${VERSION_CHECK}$ ]]; then
  echo "version check ok: ${VERSION_INSTALLED}"
  exit 0
fi

echo "version mismatch!"
echo "installed: ${VERSION_INSTALLED}"
echo "check: ${VERSION_CHECK}"
exit 1
