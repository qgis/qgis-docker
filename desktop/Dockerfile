ARG os=ubuntu
ARG release=noble

FROM ${os}:${release}
LABEL maintainer="OPENGIS.ch <info@opengis.ch>"

ARG os
ARG release
ARG repo
ARG qgis_version=master

RUN apt update && apt install -y gnupg wget software-properties-common && \
    wget -qO - https://qgis.org/downloads/qgis-2022.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    # run twice because of https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041012
    add-apt-repository "deb https://qgis.org/${repo} ${release} main" && \
    add-apt-repository "deb https://qgis.org/${repo} ${release} main" && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip qgis python3-qgis python3-qgis-common python3-venv \
      python3-pytest python3-mock xvfb qttools5-dev-tools pyqt5-dev-tools && \
    apt-get clean

# Test version
COPY scripts/check_version.sh /opt/check_version.sh
RUN /opt/check_version.sh ${qgis_version}
