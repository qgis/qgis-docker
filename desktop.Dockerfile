
ARG ubuntu_dist=jammy

FROM ubuntu:${ubuntu_dist}
LABEL maintainer="OPENGIS.ch <info@opengis.ch>"


ARG ubuntu_dist
ARG repo=ubuntu

RUN apt update && apt install -y gnupg wget software-properties-common && \
    wget -qO - https://qgis.org/downloads/qgis-2022.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    add-apt-repository "deb https://qgis.org/${repo} ${ubuntu_dist} main" && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y qgis python3-qgis python3-qgis-common \
      python3-pytest python3-mock xvfb && \
    apt-get clean
