# QGIS Server

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis-server)](https://hub.docker.com/r/qgis/qgis-server)

## General information

The Docker image is built using *Ubuntu 26.04 (resolute)*, *Debian 13 (trixie)* and, for QGIS 3 LTR only, *Ubuntu 24.04 (noble)* and official QGIS DEBs from <https://qgis.org/>.
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

This Docker container exposes HTTP on port `80` via Nginx and a direct FastCGI on port `9993` that can be used directly by an external HTTP proxy (like the provided [`compose.yaml`](compose.yaml) does).
A sample Nginx configuration for using it as a *FastCGI* backend is also [provided](conf/nginx-fcgi-sample.conf).

## Projects

Projects are mounted in `/io/data`, in any folder structure, and served by Nginx at:

| URL                      | Project                                  |
|--------------------------|------------------------------------------|
| `/ogc/<name>`            | `/io/data/<name>/<name>.qgs`             |
| `/ogc/<path>/<name>`     | `/io/data/<path>/<name>/<name>.qgs`      |
| `/ogc/<path>/<file>.qgs` | `/io/data/<path>/<file>.qgs` (or `.qgz`) |
| `/ows/?MAP=<project>`    | any project file                         |
| `/ogcapi/?MAP=<project>` | any project file (OGC API)               |

For instance, `/ogc/team/alice/roads?SERVICE=WMS&REQUEST=GetCapabilities` serves `/io/data/team/alice/roads/roads.qgs`.
The OGC API of a project is served under its `/ogc/` URL, e.g. `/ogc/team/alice/roads/ogcapi/collections` (`/wfs3` before QGIS 4.2), so `ogcapi` and `wfs3` cannot be used as folder names in the project path.
For other routes, mount a custom Nginx configuration over `/etc/nginx/nginx.conf`.

## Cross-origin requests (CORS)

The embedded Nginx does not send CORS headers by default, as a reverse proxy in front of the container may already handle them.
To let web clients on other origins query the server (e.g. `GetFeatureInfo` from a web map), set `NGINX_CORS_ALLOW_ORIGIN` to `*` or to a single origin:

```sh
docker run -e NGINX_CORS_ALLOW_ORIGIN=https://map.example.com -v $(pwd)/test/data:/io/data -p 8010:80 qgis/qgis-server:ltr
```

Preflight (`OPTIONS`) requests are then answered by Nginx directly.

## Behind a reverse proxy

The URLs in the responses (`GetCapabilities`, OGC API links) are built from the request.
Behind a reverse proxy, Nginx takes the public URL from these headers, which the proxy should set:

| Header               | Example                               |
|----------------------|---------------------------------------|
| `X-Forwarded-Host`   | `maps.example.com`                    |
| `X-Forwarded-Proto`  | `https`                               |
| `X-Forwarded-Port`   | `8443` (only for a non-default port)  |
| `X-Forwarded-Prefix` | `/api/qgis` (if served under a path)  |

For instance, with the host, scheme and prefix above, `/ogc/<name>` is announced as `https://maps.example.com/api/qgis/ogc/<name>`.
The [FastCGI sample configuration](conf/nginx-fcgi-sample.conf) handles the same headers.

For WMS, WFS, WCS and WMTS (not OGC API), a fixed URL can also be set with the `QGIS_SERVER_SERVICE_URL` [environment variable](https://docs.qgis.org/latest/en/docs/server_manual/config.html#environment-variables) or as the announced URL in the project.

## Available tags

Image name: `qgis/qgis-server`

- **QGIS stable**: `stable` | `stable-trixie`
- **QGIS LTR**: `ltr` | `ltr-trixie` | `ltr-noble`
- **QGIS version**: e.g. `4.2` | `4.2.3` | `4.2.3-trixie`
- **QGIS nightly**: `nightly` | `latest`

Tags without a distribution suffix are built on Ubuntu 26.04 (resolute).

Example:

```sh
docker pull qgis/qgis-server:ltr
```

## Docker Compose

The provided [`compose.yaml`](compose.yaml) runs QGIS Server as a *FastCGI* backend behind a separate Nginx container, serving the test project:

```sh
cd server
docker compose up -d
curl "http://localhost:8010/ogc/test_project?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities"
curl "http://localhost:8010/ogcapi/collections.json?MAP=/io/data/test_project/test_project.qgs"
```

## Running as a non-root user

By default the container starts as `root`, while Nginx workers and QGIS Server run as `www-data`.
It can also run entirely as an arbitrary non-root user, as long as it can read the mounted volumes:

```sh
docker run --user 1000 -v $(pwd)/test/data:/io/data -p 8010:80 qgis/qgis-server:ltr
```
