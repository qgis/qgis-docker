#!/usr/bin/env bash

# Builds QGIS with the options shared by the slim images and the given ones, and installs it into /install
# without what is only useful for development or the desktop application.
#
# Usage: build-qgis.sh QGIS_REF [CMAKE_OPTION...]
# QGIS_REF can be a branch, a tag or a commit

set -euo pipefail

QGIS_REF=$1
shift

mkdir -p /src/qgis
cd /src/qgis
git init -q
git fetch -q --depth 1 https://github.com/qgis/QGIS.git "${QGIS_REF}"
git checkout -q FETCH_HEAD

OPTIONS=(
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX=/usr
  -DUSE_CCACHE=ON
  # silence the ABI notes of GCC on arm64, they exceed the log limit of BuildKit
  -DCXX_EXTRA_FLAGS=-Wno-psabi
  -DENABLE_TESTS=OFF
  -DWITH_DESKTOP=OFF
  -DWITH_3D=OFF
  -DWITH_QUICK=OFF
  -DWITH_CUSTOM_WIDGETS=OFF
  -DWITH_ANALYSIS=ON
  -DWITH_BINDINGS=ON
  -DWITH_QTWEBENGINE=OFF
  -DWITH_QTSERIALPORT=OFF
  -DWITH_PDAL=OFF
  -DWITH_DRACO=OFF
  -DWITH_EXIV2=OFF
  -DWITH_GSL=OFF
  -DWITH_GRASS7=OFF
  -DWITH_GRASS8=OFF
  -DWITH_INTERNAL_SPATIALINDEX=ON
  -DUSE_OPENCL=OFF
)
cmake -S . -B build -G Ninja "${OPTIONS[@]}" "$@"
cmake --build build
DESTDIR=/install cmake --install build --strip
cd /
rm -rf /src/qgis

cd /install/usr
DROPPED=(
  include lib/cmake lib/pkgconfig lib/*/cmake lib/*/pkgconfig
  share/qgis/i18n share/qgis/resources/cpt-city-qgis-min
  share/qgis/python/console share/qgis/python/pyplugin_installer share/qgis/python/qsci_apis
  share/qgis/python/plugins/db_manager share/qgis/python/plugins/grassprovider share/qgis/python/plugins/MetaSearch
  # the sources of the landing page web app, before QGIS 4.4
  share/qgis/resources/server/src
)
rm -rf "${DROPPED[@]}"

# Python modules are not stripped by the install
find /install -type f -name '*.so*' -print0 | xargs -0 strip --strip-unneeded 2>/dev/null || true

# one du per level, as du does not count twice the same directory
for DIR in /install/usr /install/usr/lib /install/usr/share /install/usr/share/qgis /install/usr/share/qgis/python; do
  du -sh "${DIR}"/*
done | sort -h | tail -30
