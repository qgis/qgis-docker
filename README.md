# QGIS Docker Images

This repository automates the build of QGIS desktop and QGIS server Docker images.

## QGIS 4.0 (Qt6)

QGIS 4.0 images are available for distributions that ship Qt6: **Ubuntu Questing (25.10)** and **Debian Trixie**.

Use the distribution-suffixed tags to pull QGIS 4.0:

```sh
# Desktop
docker pull qgis/qgis:stable-questing
docker pull qgis/qgis:4.0-trixie

# Server
docker pull qgis/qgis-server:stable-questing
docker pull qgis/qgis-server:4.0-trixie
```

The default `latest` and `stable` tags (without suffix) still point to the current default Ubuntu LTS (Noble), which ships QGIS 3.x.
The `latest` tag will switch to QGIS 4.0 once the next Ubuntu LTS becomes the default base image.

## Desktop

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis)](https://hub.docker.com/r/qgis/qgis)

- [Documentation](./desktop/README.md)

## Server

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-server)](https://hub.docker.com/r/qgis/qgis-server)

- [Documentation](./server/README.md)
