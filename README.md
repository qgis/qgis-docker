## QGIS 3 server via Docker

[![Build Status](https://travis-ci.org/gem/oq-qgis-server.svg?branch=master)](https://travis-ci.org/gem/oq-qgis-server)

### General information

The Docker image is built using *Fedora 29* and QGIS RPMs from https://copr.fedorainfracloud.org/coprs/dani/qgis/ (QGIS 3.6) and https://copr.fedorainfracloud.org/coprs/dani/qgis-ltr/ (QGIS 3.4 LTR).
It includes *Nginx* and *Xvfb* and can be used as a standalone service (via HTTP TCP port 80) or as *FCGI* backend (via TCP port 9993).

A fallback image running *Ubuntu 18.04* is also provided as fallback for systems lacking support for `statx` syscall. See the [Requisites](#Requisites) section.
The *Fedora* container is generally more tested.

### Requisites

To be able to run *Fedora* containers you need **Docker >= 18.04** with `seccomp` support for the `statx` syscall required by Qt 5.10+. This is generally included in **libseccomp >= 2.3.3**;
a kernel with `statx` support is also required; any kernel newer than 4.11 should be ok. Please check with your vendor.

As a fallback for systems lacking `statx` support containers built on top of *Ubuntu 18.04 LTS (Bionic)* are also provided for newer releases.

See https://github.com/gem/oq-qgis-server/issues/1 for further details.

Containers are not tested on hosts running OSes other than Linux.

### Services provided

This Docker container exposes HTTP on port `80` via Nginx and a direct FastCGI on port `9993` that can be used directly by an external HTTP proxy (like the provided `docker-compose.yml` does).
A sample Nginx configuration for using it as a *FastCGI* backend is also [provided](conf/nginx-fcgi-sample.conf).

### Available tags

Image name: `openquake/qgis-server`

### QGIS 3.6
- `stable` | `3.6` | `3.6.0` | `stable-ubuntu` | `3.6-ubuntu` | `3.6.0-ubuntu`

### QGIS 3.4 LTR
- `ltr` | `3.4` | `3.4.5` | `ltr-ubuntu` | `3.4-ubuntu` | `3.4.5-ubuntu`
- `3.4.4`
- `3.4.3`
- `3.4.2`
- `3.4.1`
- `3.4.0`

Example:

```bash
$ docker pull openquake/qgis-server:ltr
```

### Build the container

#### QGIS 3.6

```bash
# Fedora based container
$ docker build -t openquake/qgis-server:3.6 -f Dockerfile.fedora .
# Ubuntu based container
$ docker build -t openquake/qgis-server:3.6 -f Dockerfile.ubuntu .
```

#### QGIS 3.4 LTR

```bash
# Fedora based container
$ docker build --build-arg repo=qgis-ltr -t openquake/qgis-server:3.4 -f Dockerfile.fedora .
# Ubuntu based container
$ docker build --build-arg repo=ubuntu-ltr -t openquake/qgis-server:3.4 -f Dockerfile.ubuntu .
```

You may skip this step. The container will be downloaded from the Docker Hub.

### Run the docker and map host data

```
$ docker run -v $(pwd)/data:/io/data -v $(pwd)/plugins:/io/plugins --name qgis-server -d -p 8010:80 openquake/qgis-server:3.4
```

`WMS` and `WFS` will be published at `http://localhost:8010/ogc/<project_name>`.

#### Access the container via bash

```
$ docker exec -ti qgis-server /bin/bash
```

where `qgis-server` is the name of the container.

#### Logs and debugging

QGIS server log can retreived via `docker logs`

```
$ docker logs [-f] qgis-server
```

where `qgis-server` is the name of the container.

Default log level is set to `warning`. Log level can be increased during container deployment passing the `-e QGIS_SERVER_LOG_LEVEL=0` option:

```
$ docker run -e QGIS_SERVER_LOG_LEVEL=0 -v $(pwd)/data:/io/data -v $(pwd)/plugins:/io/plugins --name qgis-server -d -p 8010:80 openquake/qgis-server:3.4
```

### Run the docker and map host data (via docker-compose)

Adjust first the configuration in `conf/nginx.conf` with the proper number of expected workers
and `docker-compose.yml` with the path of data folder on the host.

Then:

```
$ docker-compose up -d --scale qgis-server=N
```

Where N is the number of expected QGIS server workers.


### Data dir structure

`$(pwd)/data` must have the following structure:

```
data 
 |
 |-- <project_name>
      |-- <project_name>.qgs
```

[oq-consolidate](https://github.com/gem/oq-consolidate) may helps you in exporting data suitable for QGIS server (consolidating project and layers).

`$(pwd)/plugins` must have the following structure:

```
plugins
 |
 |-- <plugin_name>
      |-- <plugin_code>.py
      |-- metadata.txt
      |-- __init__.py
```

### Runtime customizations

The following variables can be customized during container deployment:

- `QGIS_SERVER_LOG_LEVEL`: default is `1`
- `QGIS_SERVER_PARALLEL_RENDERING`: default is `true`
- `QGIS_SERVER_MAX_THREADS`: default is `2`

See [QGIS server documentation](https://docs.qgis.org/testing/en/docs/user_manual/working_with_ogc/server/config.html#qgis-server-log-level) for further details.

It is also possible to customized the ID of the user running QGIS server processes when it is required to write to host volumes (see [notes](#notes)]:

- `QGIS_USER`: default is `nginx`


## Notes

GeoPackages do not play well with multiple processes having gpkg files opened in `rw` mode. By default QGIS server processes lack write permission on `/io/data`.
If you it required to let QGIS server write data to `/io/data` make sure that either you are using a process-safe datastore (i.e. a Postgres backend) or you are
limiting horizontal one container only at the time. QGIS server user can be customized via the `QGIS_USER` environment variable.
