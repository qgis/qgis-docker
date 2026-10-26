#!/usr/bin/env bash

# Distribution GDAL packages are built without Apache Arrow, so they lack the
# (Geo)Parquet and (Geo)Arrow drivers. Build them as plugins against the installed
# libgdal (requires GDAL >= 3.10) using the Apache Arrow apt repository.

set -e

. /etc/os-release

GDAL_VERSION=$(dpkg-query -W -f='${Version}' 'libgdal[0-9]*')
# 3.10.3+dfsg-1 -> 3.10.3
GDAL_VERSION=${GDAL_VERSION#*:}
GDAL_VERSION=${GDAL_VERSION%%+*}

if dpkg --compare-versions "${GDAL_VERSION}" lt 3.10; then
  echo "GDAL ${GDAL_VERSION} cannot build standalone plugins, skipping Parquet/Arrow drivers"
  exit 0
fi

ARROW_APT_SOURCE=https://packages.apache.org/artifactory/arrow/${ID}/apache-arrow-apt-source-latest-${VERSION_CODENAME}.deb
if ! wget -qO /tmp/apache-arrow-apt-source.deb ${ARROW_APT_SOURCE}; then
  echo "No Apache Arrow packages for ${ID} ${VERSION_CODENAME}, skipping Parquet/Arrow drivers"
  exit 0
fi
apt-get install -y /tmp/apache-arrow-apt-source.deb

# Arrow drops deprecated APIs, pin the latest version each GDAL release builds with
case ${GDAL_VERSION} in
  3.10.*) ARROW_VERSION=20.0.0 ;;
  3.12.*) ARROW_VERSION=26.0.0 ;;
esac
if [[ -n ${ARROW_VERSION} ]]; then
  printf 'Package: libarrow* libparquet*\nPin: version %s-*\nPin-Priority: 1001\n' ${ARROW_VERSION} \
    > /etc/apt/preferences.d/apache-arrow
fi
apt-get update

SAVED_APT_MARK=$(apt-mark showmanual)
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  cmake g++ make libgdal-dev libarrow-dev libarrow-dataset-dev libparquet-dev

wget -qO- https://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz | tar xz -C /tmp
for DRIVER in parquet arrow; do
  cmake -S /tmp/gdal-${GDAL_VERSION}/ogr/ogrsf_frmts/${DRIVER} -B /tmp/build-${DRIVER} \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build /tmp/build-${DRIVER} -j$(nproc)
  cmake --install /tmp/build-${DRIVER}
done

# Keep the packages providing the plugins' shared libraries, remove the build dependencies.
# Not limited to libarrow*/libparquet*: Arrow packages miss dependencies on unversioned libraries.
apt-mark auto '.*' > /dev/null
apt-mark manual ${SAVED_APT_MARK} > /dev/null
ldd /usr/lib/*/gdalplugins/ogr_Parquet.so /usr/lib/*/gdalplugins/ogr_Arrow.so \
  | awk '/=>/ { so = $(NF-1); gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
  | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u \
  | xargs -r apt-mark manual > /dev/null
apt-get purge -y --auto-remove
apt-get clean
rm -rf /tmp/apache-arrow-apt-source.deb /tmp/gdal-${GDAL_VERSION} /tmp/build-*

# GDAL only logs plugin loading errors, make sure the drivers are registered
python3 -c "
import ctypes, ctypes.util
gdal = ctypes.CDLL(ctypes.util.find_library('gdal'))
gdal.GDALAllRegister()
gdal.GDALGetDriverByName.restype = ctypes.c_void_p
assert gdal.GDALGetDriverByName(b'Parquet') and gdal.GDALGetDriverByName(b'Arrow')
"
