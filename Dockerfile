# vi:syntax=dockerfile
FROM fedora:28
MAINTAINER Daniele Viganò <daniele@openquake.org>

RUN dnf -y install dnf-plugins-core xorg-x11-server-Xvfb && \
    dnf copr enable -y dani/qgis && \
    dnf install -y nginx spawn-fcgi qgis-server && \
    dnf clean all

# This part is kept to allow the container to be used in
# standalone mode, without composing it with 'nginx'
ADD conf/qgis-server-nginx.conf /etc/nginx/nginx.conf
ADD start-xvfb-nginx.sh /usr/local/bin/start-xvfb-nginx.sh

RUN useradd -u 9999 qgis

ENV QGIS_PREFIX_PATH /usr
ENV QGIS_SERVER_LOG_FILE /tmp/qgis-server.log
ENV QGIS_SERVER_LOG_LEVEL 0
ENV QGIS_SERVER_PARALLEL_RENDERING true
ENV QGIS_SERVER_MAX_THREADS 2

ENV QT_GRAPHICSSYSTEM raster
ENV DISPLAY :99

WORKDIR /tmp

EXPOSE 80
CMD /usr/local/bin/start-xvfb-nginx.sh
