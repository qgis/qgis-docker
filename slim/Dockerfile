# syntax=docker/dockerfile:1

# QGIS libraries, Python bindings and qgis_process, without desktop nor server,
# built from source on top of a slim GDAL with Arrow and Parquet support

ARG os=ubuntu
ARG release=resolute

FROM ${os}:${release} AS gdal

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      bison build-essential ca-certificates ccache cmake curl flex git ninja-build pkgconf swig \
      # GDAL
      libarrow-acero-dev libarrow-dataset-dev libarrow-dev libparquet-dev \
      libcurl4-openssl-dev libdeflate-dev libexpat1-dev libgeos-dev libjpeg-dev libopenjp2-7-dev \
      libpng-dev libpq-dev libproj-dev libspatialite-dev libsqlite3-dev libssl-dev libwebp-dev libzstd-dev \
      python3-dev python3-numpy python3-pip python3-setuptools \
      # QGIS
      libprotobuf-dev libqca-qt6-dev libqscintilla2-qt6-dev libzip-dev protobuf-compiler \
      qt6-5compat-dev qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-l10n-tools \
      qt6-multimedia-dev qt6-positioning-dev qt6-svg-dev qt6-tools-dev qtkeychain-qt6-dev \
      pyqt6-dev pyqt6.qsci-dev python3-pyqt6 python3-pyqt6.qtmultimedia python3-pyqt6.qtpositioning \
      python3-pyqt6.sip python3-pyqtbuild sip-tools \
    && rm -rf /var/lib/apt/lists/*

ENV CCACHE_DIR=/root/.ccache

# GDAL is installed in the builder to compile QGIS against it, and in /install for the final image
ARG gdal_version=v3.13.3
RUN --mount=type=cache,id=ccache,target=/root/.ccache \
    mkdir -p /src/gdal && cd /src/gdal \
    && curl -fsSL https://github.com/OSGeo/gdal/archive/refs/tags/${gdal_version}.tar.gz | tar xz --strip-components=1 \
    && cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DBUILD_TESTING=OFF \
      -DBUILD_PYTHON_BINDINGS=ON \
      -DBUILD_JAVA_BINDINGS=OFF \
      -DBUILD_CSHARP_BINDINGS=OFF \
      -DGDAL_USE_EXTERNAL_LIBS=OFF \
      -DGDAL_USE_ARROW=ON \
      -DGDAL_USE_ARROWCOMPUTE=ON \
      -DGDAL_USE_ARROWDATASET=ON \
      -DGDAL_USE_PARQUET=ON \
      -DGDAL_USE_CURL=ON \
      -DGDAL_USE_DEFLATE=ON \
      -DGDAL_USE_EXPAT=ON \
      -DGDAL_USE_GEOS=ON \
      -DGDAL_USE_ICONV=ON \
      -DGDAL_USE_JPEG=ON \
      -DGDAL_USE_OPENJPEG=ON \
      -DGDAL_USE_OPENSSL=ON \
      -DGDAL_USE_PNG=ON \
      -DGDAL_USE_POSTGRESQL=ON \
      -DGDAL_USE_SPATIALITE=ON \
      -DGDAL_USE_SQLITE3=ON \
      -DGDAL_USE_WEBP=ON \
      -DGDAL_USE_ZLIB=ON \
      -DGDAL_USE_ZSTD=ON \
    && cmake --build build \
    && DEB_PYTHON_INSTALL_LAYOUT=deb_system cmake --install build --strip \
    && DEB_PYTHON_INSTALL_LAYOUT=deb_system DESTDIR=/install cmake --install build --strip \
    && rm -rf /src/gdal

FROM gdal AS builder

# qgis_ref can be a branch, a tag or a commit
ARG qgis_ref=master
RUN --mount=type=cache,id=ccache,target=/root/.ccache \
    mkdir -p /src/qgis && cd /src/qgis \
    && git init -q \
    && git fetch -q --depth 1 https://github.com/qgis/QGIS.git ${qgis_ref} \
    && git checkout -q FETCH_HEAD \
    && cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DUSE_CCACHE=ON \
      -DENABLE_TESTS=OFF \
      -DWITH_DESKTOP=OFF \
      -DWITH_SERVER=OFF \
      -DWITH_3D=OFF \
      -DWITH_QUICK=OFF \
      -DWITH_CUSTOM_WIDGETS=OFF \
      # the gui library is required by the processing plugin
      -DWITH_GUI=ON \
      -DWITH_ANALYSIS=ON \
      -DWITH_BINDINGS=ON \
      -DWITH_QGIS_PROCESS=ON \
      -DWITH_QTWEBENGINE=OFF \
      -DWITH_QTSERIALPORT=OFF \
      -DWITH_PDAL=OFF \
      -DWITH_DRACO=OFF \
      -DWITH_EXIV2=OFF \
      -DWITH_GSL=OFF \
      -DWITH_GRASS7=OFF \
      -DWITH_GRASS8=OFF \
      -DWITH_INTERNAL_SPATIALINDEX=ON \
      -DUSE_OPENCL=OFF \
    && cmake --build build \
    && DESTDIR=/install cmake --install build --strip \
    && rm -rf /src/qgis

# Drop what is only useful for development or the desktop application
RUN cd /install/usr \
    && rm -rf include lib/cmake lib/pkgconfig lib/*/cmake lib/*/pkgconfig share/qgis/i18n \
      share/qgis/python/console share/qgis/python/pyplugin_installer share/qgis/python/qsci_apis \
      share/qgis/python/plugins/db_manager share/qgis/python/plugins/grassprovider share/qgis/python/plugins/MetaSearch \
    # Python modules are not stripped by the install
    && (find /install -type f -name '*.so*' | xargs strip --strip-unneeded 2>/dev/null || true) \
    && du -sh /install/usr/* /install/usr/share/* /install/usr/share/qgis/* | sort -h

# Qt Multimedia libraries are copied, not installed from their packages, to leave out the FFmpeg plugin and codecs
COPY slim/runtime-packages.sh /usr/local/bin/runtime-packages.sh
RUN mkdir /runtime \
    && runtime-packages.sh /install libqt6multimedia6 libqt6multimediawidgets6 libqt6spatialaudio6 python3-pyqt6.qtmultimedia \
      > /runtime/packages.txt \
    && cat /runtime/packages.txt

FROM ${os}:${release}
LABEL maintainer="OPENGIS.ch <info@opengis.ch>"

ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=bind,from=builder,source=/runtime,target=/runtime \
    apt-get update \
    && xargs -a /runtime/packages.txt apt-get install -y --no-install-recommends \
      ca-certificates libqca-qt6-plugins libqt6sql6-sqlite python3 python3-psycopg2 \
      python3-pyqt6 python3-pyqt6.qsci python3-pyqt6.qtpositioning qt6-qpa-plugins \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install/ /
RUN ldconfig

ENV QGIS_PREFIX_PATH=/usr
ENV PYTHONPATH=/usr/share/qgis/python:/usr/share/qgis/python/plugins
ENV QT_QPA_PLATFORM=offscreen
