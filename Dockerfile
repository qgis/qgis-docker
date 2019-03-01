# -*- coding: utf-8 -*-
# vim: tabstop=4 shiftwidth=4 softtabstop=4
# vim: syntax=dockerfile
#
# oq-qgis-server
# Copyright (C) 2018-2019 GEM Foundation
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

FROM fedora:29
LABEL maintainer="Daniele Viganò <daniele@openquake.org>"

ARG repo=qgis

RUN dnf -y install dnf-plugins-core xorg-x11-server-Xvfb && \
    dnf copr enable -y dani/$repo && \
    dnf install -y nginx spawn-fcgi qgis-server && \
    dnf clean all

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

ENV QT_GRAPHICSSYSTEM raster
ENV DISPLAY :99

WORKDIR /tmp

EXPOSE 80
CMD /usr/local/bin/start-xvfb-nginx.sh
