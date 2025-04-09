# QGIS Server

[Docker Hub](https://hub.docker.com/r/qgis/qgis-server)

**Warning**

There are discussions on how to build these images and they are not considered stable.
They are considered as NOT production ready.

## General information

The Docker image is built using *Ubuntu 20.04 (focal), 22.04 (jammy) and 24.04 (noble)* and official QGIS DEBs from <https://qgis.org/>.
It includes *Nginx* and *Xvfb* and can be used as a standalone service (via HTTP TCP port 80) or as *FCGI* backend (via TCP port 9993).

## Requisites

You need **Docker >= 18.04** with `seccomp`. Support for the `statx` syscall, required by Qt 5.10+, may be made necessary in the future. This is generally included in **libseccomp >= 2.3.3**;
a kernel with `statx` support is also required; any kernel newer than 4.11 should be ok. Please check with your vendor.

Known good configurations are:
- Ubuntu 18.04.2+
- CentOS 8
- Fedora 29+

See <https://github.com/qgis/qgis-docker/issues/1> for further details.

Containers are not tested on hosts running OSes other than Linux.

## Services provided

This Docker container exposes HTTP on port `80` via Nginx and a direct FastCGI on port `9993` that can be used directly by an external HTTP proxy (like the provided `docker-compose.yml` does).
A sample Nginx configuration for using it as a *FastCGI* backend is also [provided](conf/nginx-fcgi-sample.conf).

## Available tags

Image name: `qgis/qgis-server`

- **QGIS stable**: `stable` | `stable-ubuntu`
- **QGIS LTR**: `ltr` | `ltr-ubuntu`

Example:

```sh
docker pull qgis/qgis-server:ltr
