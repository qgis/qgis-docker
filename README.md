# QGIS Docker Images

This repository automates the build of QGIS desktop and QGIS server Docker images.

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
