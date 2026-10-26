# -*- coding: utf-8 -*-
# vim: tabstop=4 shiftwidth=4 softtabstop=4
# vim: syntax=dockerfile
#
# oq-qgis-server
# Copyright (C) 2018-2020 GEM Foundation
#
# oq-qgis-server is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# oq-qgis-server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ARG os=ubuntu
ARG release=resolute

FROM ${os}:${release} AS qgis-server
LABEL maintainer="OPENGIS.ch <info@opengis.ch>"

ARG os
ARG release
ARG repo
ARG qgis_version

RUN apt update && apt install -y gnupg wget && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/${repo} ${release} main" > /etc/apt/sources.list.d/qgis.list && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y xvfb nginx-core spawn-fcgi qgis-server python3-qgis && \
    apt clean all

# QGIS 3 packages ship the sources of the landing page web app without building it,
# leaving the landing page blank: build it unless the packages already provide it
FROM --platform=$BUILDPLATFORM node:22-slim AS landingpage
COPY --from=qgis-server /usr/share/qgis/resources/server /server
RUN mkdir /dist && \
    if [ -d /server/src/landingpage ] && [ ! -d /server/api/ogc/static/landingpage ]; then \
      cd /server/src/landingpage && \
      yarn install --frozen-lockfile && \
      yarn build --dest /dist/landingpage; \
    fi

FROM qgis-server
COPY --from=landingpage /dist/ /usr/share/qgis/resources/server/api/ogc/static/

# This part is kept to allow the container to be used in
# standalone mode, without composing it with 'nginx'
ADD server/conf/qgis-server-nginx.conf /etc/nginx/nginx.conf
ADD server/start-xvfb-nginx.sh /usr/local/bin/start-xvfb-nginx.sh

ENV QGIS_PREFIX_PATH /usr
ENV QGIS_PLUGINPATH /io/plugins
ENV QGIS_SERVER_LOG_LEVEL 1
ENV QGIS_SERVER_LOG_STDERR true
ENV QGIS_SERVER_PARALLEL_RENDERING true
ENV QGIS_SERVER_MAX_THREADS 2
ENV QGIS_AUTH_DB_DIR_PATH /tmp/

ENV DISPLAY :99
ENV HOME /var/lib/qgis

# Writable by anyone, so that the container can also run as an arbitrary non-root user
RUN mkdir $HOME /tmp/.X11-unix && \
    mkdir -p /etc/nginx/qgis.d && \
    chmod 1777 $HOME /tmp/.X11-unix /etc/nginx/qgis.d /var/lib/nginx /run
WORKDIR $HOME

EXPOSE 80/tcp 9993/tcp
CMD /usr/local/bin/start-xvfb-nginx.sh
