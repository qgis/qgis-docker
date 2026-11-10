# QGIS slim

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-slim)](https://hub.docker.com/r/qgis/qgis-slim)
[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-core-slim)](https://hub.docker.com/r/qgis/qgis-core-slim)
[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-server-slim)](https://hub.docker.com/r/qgis/qgis-server-slim)

Three headless QGIS images, from two QGIS builds:

- `qgis/qgis-slim`, for scripts and processing: the QGIS libraries, including the gui library that the processing plugin requires, the Python bindings and `qgis_process`
- `qgis/qgis-core-slim`, for PyQGIS scripts without processing: QGIS built without its gui library, so without the processing plugin and `qgis_process`
- `qgis/qgis-server-slim`: `qgis/qgis-core-slim` with [QGIS Server](#qgis-server-slim), set up as `qgis/qgis-server`

Unlike the other images, they are built from source on *Ubuntu 26.04 (resolute)*, for `linux/amd64` and `linux/arm64`:

- GDAL is compiled with a limited set of drivers' dependencies, including Apache Arrow and Parquet (GeoParquet, GeoArrow)
- QGIS is compiled with the core and analysis libraries, but without the desktop application, 3D, PDAL, translations, cpt-city color ramps and development files
- Mesa is replaced by empty packages: rendering works offscreen or on Xvfb, but OpenGL is not available

```sh
docker pull qgis/qgis-slim:nightly  # master, also tagged latest
docker pull qgis/qgis-slim:stable   # latest release
docker pull qgis/qgis-slim:4.2      # latest patch release of a minor version, also tagged with it, e.g. 4.2.3
```

`qgis/qgis-core-slim` and `qgis/qgis-server-slim` have the same tags.

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

The images include the Python packages numpy, PyYAML, pydantic, psycopg (3) and psycopg2.
Additional ones can be installed with `pip install`, into `/usr/local`.

`xvfb-run` provides a virtual X display for what requires one, Qt uses it with `QT_QPA_PLATFORM=xcb`:

```sh
docker run --rm qgis/qgis-slim:nightly xvfb-run -a env QT_QPA_PLATFORM=xcb python3 /data/script.py
```

`qgis/qgis-core-slim` runs the same scripts, as long as they use neither processing nor `qgis.gui`:
for instance writing layers with `QgsVectorFileWriter` instead of running algorithms.

## QGIS Server slim

`qgis/qgis-server-slim` runs QGIS Server with the Nginx configuration, start script and environment variables of `qgis/qgis-server`.
The routes, landing page, CORS, reverse proxy headers and non-root user described in its [documentation](../server/README.md) work the same:

```sh
docker run -d -p 8010:80 -v "${PWD}/server/test/data:/io/data" qgis/qgis-server-slim:stable
curl "http://localhost:8010/ogc/test_project?SERVICE=WMS&REQUEST=GetCapabilities"
```

Compared to `qgis/qgis-server`, it also runs on arm64 and reads GeoParquet, but it has the limitations listed above.
Without translations, the server only answers in English.
`tini` is the init process.

Built on `qgis/qgis-core-slim`, it does not include the gui library: Python server plugins are loaded from `/io/plugins`,
with the Python packages listed above, but not the ones that use processing or `qgis.gui`.

## Building

The `slim`, `core-slim` and `server-slim` targets build each image, the last two from the same QGIS build:

```sh
docker build -f slim/Dockerfile --target slim -t qgis/qgis-slim .
docker build -f slim/Dockerfile --target core-slim -t qgis/qgis-core-slim .
docker build -f slim/Dockerfile --target server-slim -t qgis/qgis-server-slim .
```

The `qgis_ref` (branch, tag or commit) and `gdal_version` build arguments select the versions to build.
