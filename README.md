# QGIS Docker Images

This repository automates the build of QGIS desktop and QGIS server Docker images.

The desktop and server images are only built for `linux/amd64`, as the QGIS package repositories do not provide arm64 packages.
On arm64 hosts (e.g. Apple Silicon), they can be run under emulation with `--platform linux/amd64`.
The slim image is built from source for both `linux/amd64` and `linux/arm64`.

## QGIS 4 (Qt6)

QGIS 4 images are available for distributions that ship Qt6: **Ubuntu Resolute (26.04 LTS)** and **Debian Trixie**.

Ubuntu Resolute is the default base image, so the tags without suffix (`latest`, `stable`, `ltr`, ...) are built on it:

```sh
# Desktop
docker pull qgis/qgis:stable
docker pull qgis/qgis:stable-trixie

# Server
docker pull qgis/qgis-server:stable
docker pull qgis/qgis-server:stable-trixie
```

Ubuntu Questing (25.10) has reached its end of life: the `*-questing` tags are no longer updated.

## Desktop

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis)](https://hub.docker.com/r/qgis/qgis)

- [Documentation](./desktop/README.md), including instructions to test QGIS plugins

## Server

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-server)](https://hub.docker.com/r/qgis/qgis-server)

- [Documentation](./server/README.md)

## Slim

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-slim)](https://hub.docker.com/r/qgis/qgis-slim)

Headless QGIS (libraries, Python bindings and `qgis_process`) on a GDAL with Arrow and Parquet support.

- [Documentation](./slim/README.md)
