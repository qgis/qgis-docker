# QGIS slim

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-slim)](https://hub.docker.com/r/qgis/qgis-slim)

A headless QGIS image for scripts and processing: the QGIS libraries, the Python bindings and `qgis_process`, without QGIS desktop and QGIS server.

Unlike the other images, it is built from source on *Ubuntu 26.04 (resolute)*, for `linux/amd64` and `linux/arm64`:

- GDAL is compiled with a limited set of drivers' dependencies, including Apache Arrow and Parquet (GeoParquet, GeoArrow)
- QGIS is compiled with the core, analysis and gui libraries and the processing plugin, but without the desktop application, server, 3D, PDAL, translations, cpt-city color ramps and development files
- Mesa is replaced by empty packages: rendering works offscreen, but OpenGL is not available

```sh
docker pull qgis/qgis-slim:nightly  # master, also tagged latest
docker pull qgis/qgis-slim:stable   # latest release
docker pull qgis/qgis-slim:4.2      # latest patch release of a minor version, also tagged with it, e.g. 4.2.3
```

The stable and long term releases are built from their latest patch release, since QGIS 4.2.
`ltr` is added once the long term release is QGIS 4.2 or newer.
The images of older minor versions remain available, but are not rebuilt anymore.

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

The image includes the Python packages numpy, PyYAML, pydantic, psycopg (3) and psycopg2.
Additional ones can be installed with `pip install`, into `/usr/local`.

`xvfb-run` provides a virtual X display for what requires one, Qt uses it with `QT_QPA_PLATFORM=xcb`:

```sh
docker run --rm qgis/qgis-slim:nightly xvfb-run -a env QT_QPA_PLATFORM=xcb python3 /data/script.py
```

## Building

```sh
docker build -f slim/Dockerfile -t qgis/qgis-slim .
```

The `qgis_ref` (branch, tag or commit) and `gdal_version` build arguments select the versions to build.
