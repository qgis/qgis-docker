ARG os=ubuntu
ARG release=questing

FROM ${os}:${release}
LABEL maintainer="OPENGIS.ch <info@opengis.ch>"

ARG os
ARG release
ARG repo
ARG qgis_version=master

RUN apt update && apt install -y gnupg wget && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/${repo} ${release} main" > /etc/apt/sources.list.d/qgis.list && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip qgis python3-qgis python3-qgis-common python3-venv \
      python3-pytest python3-mock python3-pexpect xvfb && \
    # Install Qt5 or Qt6 tools depending on the QGIS version (4.x+ uses Qt6)
    if dpkg -l python3-pyqt6 > /dev/null 2>&1; then \
      apt-get install -y qt6-tools-dev-tools pyqt6-dev-tools; \
    else \
      apt-get install -y qttools5-dev-tools pyqt5-dev-tools; \
    fi && \
    apt-get clean

# Test version
COPY scripts/check_version.sh /opt/check_version.sh
RUN /opt/check_version.sh ${qgis_version}

# Install test runner scripts for plugin testing
COPY desktop/scripts/test_runner/qgis_setup.sh /usr/bin/qgis_setup.sh
COPY desktop/scripts/test_runner/qgis_startup.py /usr/bin/qgis_startup.py
COPY desktop/scripts/test_runner/qgis_testrunner.py /usr/bin/qgis_testrunner.py
COPY desktop/scripts/test_runner/qgis_testrunner.sh /usr/bin/qgis_testrunner.sh
RUN chmod +x /usr/bin/qgis_setup.sh /usr/bin/qgis_testrunner.sh

ENV PYTHONPATH=/usr/share/qgis/python
