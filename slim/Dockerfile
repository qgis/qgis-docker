# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

# QGIS built from source on top of a slim GDAL with Arrow and Parquet support, without the desktop application.
# QGIS is compiled once for both targets:
# - slim (qgis/qgis-slim): the QGIS libraries, Python bindings and qgis_process
# - server-slim (qgis/qgis-server-slim): the slim image with QGIS Server, set up as the qgis-server image
#
# SecretsUsedInArgOrEnv only matches the variable names: QGIS_AUTH_DB_DIR_PATH is a directory, not a secret

ARG os=ubuntu
ARG release=resolute

FROM ${os}:${release} AS gdal

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential ca-certificates ccache cmake curl git ninja-build pkgconf swig \
      libarrow-acero-dev libarrow-dataset-dev libarrow-dev libparquet-dev \
      libcurl4-openssl-dev libdeflate-dev libexpat1-dev libgeos-dev libjpeg-dev libopenjp2-7-dev \
      libpng-dev libpq-dev libproj-dev libspatialite-dev libsqlite3-dev libssl-dev libwebp-dev libzstd-dev \
      python3-dev python3-numpy python3-pip python3-setuptools \
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

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      bison flex libfcgi-dev libprotobuf-dev libqca-qt6-dev libqscintilla2-qt6-dev libzip-dev protobuf-compiler \
      qt6-5compat-dev qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-l10n-tools \
      qt6-multimedia-dev qt6-positioning-dev qt6-svg-dev qt6-tools-dev qtkeychain-qt6-dev \
      pyqt6-dev pyqt6.qsci-dev python3-pyqt6 python3-pyqt6.qsci python3-pyqt6.qtmultimedia \
      python3-pyqt6.qtpositioning python3-pyqt6.sip python3-pyqtbuild sip-tools \
    && rm -rf /var/lib/apt/lists/*

# Node.js and Yarn 1 build the web app of the server landing page: the lockfiles of QGIS are not supported by
# the Yarn 4 of Ubuntu
COPY --from=node:22-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:22-slim /opt/ /opt/
RUN ln -s /opt/yarn-v*/bin/yarn /usr/local/bin/yarn && yarn --version

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
      # silence the ABI notes of GCC on arm64, they exceed the log limit of BuildKit
      -DCXX_EXTRA_FLAGS=-Wno-psabi \
      -DENABLE_TESTS=OFF \
      -DWITH_DESKTOP=OFF \
      # the server files are split from the install below, for the server image only
      -DWITH_SERVER=ON \
      -DWITH_SERVER_LANDINGPAGE_WEBAPP=ON \
      -DYARN_INSTALL_OPT=--frozen-lockfile \
      # where the packages, and so the nginx configuration of the qgis-server image, have it
      -DQGIS_CGIBIN_SUBDIR=lib/cgi-bin \
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
    && rm -rf include lib/cmake lib/pkgconfig lib/*/cmake lib/*/pkgconfig share/qgis/i18n share/qgis/resources/cpt-city-qgis-min \
      share/qgis/python/console share/qgis/python/pyplugin_installer share/qgis/python/qsci_apis \
      share/qgis/python/plugins/db_manager share/qgis/python/plugins/grassprovider share/qgis/python/plugins/MetaSearch \
      # the sources of the landing page web app, before QGIS 4.4
      share/qgis/resources/server/src \
    # Python modules are not stripped by the install
    && (find /install -type f -name '*.so*' | xargs strip --strip-unneeded 2>/dev/null || true) \
    # one du per level, as du does not count twice the same directory
    && for DIR in /install/usr /install/usr/lib /install/usr/share /install/usr/share/qgis /install/usr/share/qgis/python; do \
      du -sh ${DIR}/*; \
    done | sort -h | tail -30

# QGIS Server is moved to its own staging directory, which only the server image copies:
# a path that does not exist anymore fails the build
RUN cd /install \
    && for FILE in usr/bin/qgis_mapserver usr/lib/cgi-bin usr/lib/libqgis_server.so* usr/lib/qgis/server \
      usr/share/qgis/python/qgis/_server* usr/share/qgis/python/qgis/server usr/share/qgis/resources/server; do \
      mkdir -p /install-server/$(dirname ${FILE}) && mv ${FILE} /install-server/${FILE} || exit 1; \
    done \
    && test -f /install-server/usr/share/qgis/resources/server/api/ogc/static/landingpage/index.html \
    && du -sh /install-server/usr/*/* /install-server/usr/share/qgis/*/*

# Qt Multimedia libraries are copied, not installed from their packages, to leave out the FFmpeg plugin and codecs
COPY slim/runtime-packages.sh /usr/local/bin/runtime-packages.sh
RUN mkdir /runtime \
    && runtime-packages.sh /install libqt6multimedia6 libqt6multimediawidgets6 libqt6spatialaudio6 python3-pyqt6.qtmultimedia \
      > /runtime/packages.txt \
    && runtime-packages.sh /install-server > /runtime/server-packages.txt \
    && tail -n +1 /runtime/*.txt

FROM ${os}:${release} AS slim
LABEL maintainer="OPENGIS.ch <info@opengis.ch>"

ARG DEBIAN_FRONTEND=noninteractive

# Mesa and LLVM, required by the EGL, GLX and EGLFS libraries of Qt, are not needed to render offscreen without 3D:
# empty packages stand in for them
RUN for PACKAGE in libegl-mesa0 libgbm1 libglx-mesa0; do \
      mkdir -p /tmp/${PACKAGE}/DEBIAN \
      && printf 'Package: %s\nVersion: 99\nArchitecture: all\nMaintainer: QGIS <info@qgis.org>\nDescription: Empty package replacing Mesa in qgis-slim\n' \
        ${PACKAGE} > /tmp/${PACKAGE}/DEBIAN/control \
      && dpkg-deb --build /tmp/${PACKAGE} /tmp/${PACKAGE}.deb \
      && dpkg -i /tmp/${PACKAGE}.deb; \
    done \
    && rm -rf /tmp/*

RUN --mount=type=bind,from=builder,source=/runtime,target=/runtime \
    apt-get update \
    && xargs -a /runtime/packages.txt apt-get install -y --no-install-recommends \
      ca-certificates libqca-qt6-plugins libqt6sql6-sqlite pyqt6-dev-tools python3 python3-numpy python3-pip \
      python3-psycopg python3-psycopg2 python3-pydantic python3-pyqt6 python3-pyqt6.qsci python3-pyqt6.qtpositioning \
      python3-yaml qt6-qpa-plugins tini xvfb \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install/ /
RUN ldconfig

ENV LANG=C.UTF-8
ENV QGIS_PREFIX_PATH=/usr
ENV PYTHONPATH=/usr/share/qgis/python:/usr/share/qgis/python/plugins
# pip installs into /usr/local, next to the Python packages of the system
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV QT_QPA_PLATFORM=offscreen
# Qt Multimedia looks for PipeWire, which is not installed
ENV QT_LOGGING_RULES=qt.multimedia.symbolsresolver.warning=false

# qgis_process only loads the Python processing providers enabled in the user profile,
# the GDAL and QGIS providers are split from the processing plugin since QGIS 4.4
RUN for PLUGIN in gdalprovider qgisprovider; do \
      if [ -d /usr/share/qgis/python/plugins/${PLUGIN} ]; then qgis_process plugins enable ${PLUGIN} || exit 1; fi; \
    done

# an init process forwards the signals and reaps the zombie processes, xvfb-run hangs if it is the PID 1
ENTRYPOINT ["/usr/bin/tini", "--"]

# QGIS Server on the slim image, with the Nginx configuration, start script and settings of the qgis-server image
FROM slim AS server-slim

ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=type=bind,from=builder,source=/runtime,target=/runtime \
    apt-get update \
    && xargs -a /runtime/server-packages.txt apt-get install -y --no-install-recommends fontconfig nginx spawn-fcgi \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install-server/ /
RUN ldconfig

COPY server/conf/qgis-server-nginx.conf /etc/nginx/nginx.conf
COPY server/start-xvfb-nginx.sh /usr/local/bin/start-xvfb-nginx.sh

ENV QGIS_PLUGINPATH=/io/plugins
ENV QGIS_SERVER_LOG_LEVEL=1
ENV QGIS_SERVER_LOG_STDERR=true
ENV QGIS_SERVER_PARALLEL_RENDERING=true
ENV QGIS_SERVER_MAX_THREADS=2
ENV QGIS_AUTH_DB_DIR_PATH=/tmp/

# QGIS Server does not print offscreen: Qt uses the X display of Xvfb, started by the start script
ENV DISPLAY=:99
ENV QT_QPA_PLATFORM=
ENV HOME=/var/lib/qgis

# Writable by anyone, so that the container can also run as an arbitrary non-root user
RUN mkdir $HOME /tmp/.X11-unix \
    && mkdir -p /etc/nginx/qgis.d \
    && chmod 1777 $HOME /tmp/.X11-unix /etc/nginx/qgis.d /var/lib/nginx /run
WORKDIR $HOME

EXPOSE 80/tcp 9993/tcp
CMD ["/usr/local/bin/start-xvfb-nginx.sh"]
