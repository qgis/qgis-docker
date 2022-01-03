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

ARG ubuntu_dist=focal

FROM ubuntu:${ubuntu_dist}
LABEL maintainer="GEM Foundation <devops@openquake.org>"

ARG ubuntu_dist
ARG repo=ubuntu

RUN apt update && apt install -y gnupg wget software-properties-common && \
    wget -qO - https://qgis.org/downloads/qgis-2021.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    add-apt-repository "deb https://qgis.org/${repo} ${ubuntu_dist} main" && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y xvfb nginx-core spawn-fcgi qgis-server python3-qgis && \
    apt clean all

# This part is kept to allow the container to be used in
# standalone mode, without composing it with 'nginx'
ADD conf/qgis-server-nginx.conf /etc/nginx/nginx.conf
ADD start-xvfb-nginx.sh /usr/local/bin/start-xvfb-nginx.sh

ENV QGIS_PREFIX_PATH /usr
ENV QGIS_PLUGINPATH /io/plugins
ENV QGIS_SERVER_LOG_LEVEL 1
ENV QGIS_SERVER_LOG_STDERR true
ENV QGIS_SERVER_PARALLEL_RENDERING true
ENV QGIS_SERVER_MAX_THREADS 2
ENV QGIS_AUTH_DB_DIR_PATH /tmp/

ENV QT_GRAPHICSSYSTEM raster
ENV DISPLAY :99
ENV HOME /var/lib/qgis

RUN mkdir $HOME && \
    chmod 1777 $HOME
WORKDIR $HOME

EXPOSE 80/tcp 9993/tcp
CMD /usr/local/bin/start-xvfb-nginx.sh
