# QGIS slim

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-slim)](https://hub.docker.com/r/qgis/qgis-slim)

A headless QGIS image for scripts and processing: the QGIS libraries, the Python bindings and `qgis_process`, without QGIS desktop and QGIS server.

Unlike the other images, it is built from source on *Ubuntu 26.04 (resolute)*, for `linux/amd64` and `linux/arm64`:

- GDAL is compiled with a limited set of drivers' dependencies, including Apache Arrow and Parquet (GeoParquet, GeoArrow)
- QGIS is compiled with the core, analysis and gui libraries and the processing plugin, but without the desktop application, server, 3D, PDAL, translations and development files
- Mesa is replaced by empty packages: rendering works offscreen, but OpenGL is not available

```sh
docker pull qgis/qgis-slim:nightly  # master, also tagged latest
docker pull qgis/qgis-slim:stable   # latest release, also tagged with its version, e.g. 4.2 and 4.2.3
```

`ltr` is built once the long term release is QGIS 4 (Qt6).

## Usage

Run an algorithm with `qgis_process`:

```sh
docker run --rm -v "${PWD}:/data" qgis/qgis-slim:nightly \
  qgis_process run native:buffer --INPUT=/data/input.gpkg --DISTANCE=10 --OUTPUT=/data/buffer.parquet
```

Or a PyQGIS script:

```python
from qgis.core import QgsApplication

app = QgsApplication([], False)
app.initQgis()

import processing
from processing.core.Processing import Processing

Processing.initialize()
processing.run("native:buffer", {"INPUT": "/data/input.gpkg", "DISTANCE": 10, "OUTPUT": "/data/buffer.parquet"})
```

```sh
docker run --rm -v "${PWD}:/data" qgis/qgis-slim:nightly python3 /data/script.py
```

`QT_QPA_PLATFORM` is set to `offscreen` and `PYTHONPATH` includes the QGIS Python modules and plugins.

## Building

```sh
docker build -f slim/Dockerfile -t qgis/qgis-slim .
```

The `qgis_ref` (branch, tag or commit) and `gdal_version` build arguments select the versions to build.
