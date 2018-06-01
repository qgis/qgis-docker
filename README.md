## QGIS 3 server via Docker

Work in progress.

### Build the container

```bash
$ docker build --rm=true -t openquake/qgis-server:3 -f Dockerfile .
```
You may skip this step. The container will be downloaded from the Docker Hub.

### Run the docker and map host data (development)

```
$ docker run -v $(pwd)/data:/var/www/data -d -p 8010:80 openquake/qgis-server:3
```

`WMS` and `WFS` will be published at `http://localhost:8010/ogc/<project_name>`.

#### Debug mode

```
$ docker run -v $(pwd)/data:/var/www/data -t -i --rm -p 8010:80 openquake/qgis-server:3 /bin/bash
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


### Services provided

This Docker container exposes HTTP on port `80` via Nginx and a direct FastCGI on port `9993` that can be used directly by an external HTTP proxy (like the provided `docker-compose.yml` does)
