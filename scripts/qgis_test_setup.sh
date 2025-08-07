#!/usr/bin/env bash

# Makes the qgis_setup.sh script available for plugin testing

# Usage: qgis_test_setup.sh <docker_tag> <plugin_name>, e.g. ./qgis_test_setup.sh 3.44.1

set -euo pipefail

# Check if version argument is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <QGIS git ref, e.g. final-3_44_1 or master>"
  exit 1
fi

# Convert docker version to branch name
QGIS_REF="$1"

SETUP_SCRIPT_URL="https://raw.githubusercontent.com/qgis/QGIS/${QGIS_REF}/.docker/qgis_resources/test_runner/qgis_setup.sh"
SETUP_SCRIPT_PATH="/usr/bin/$(basename ${SETUP_SCRIPT_URL})"

STARTUP_SCRIPT_URL="https://raw.githubusercontent.com/qgis/QGIS/${QGIS_REF}/.docker/qgis_resources/test_runner/qgis_startup.py"
STARTUP_SCRIPT_PATH="/usr/bin/$(basename ${STARTUP_SCRIPT_URL})"

echo "Downloading qgis_setup.sh and friends from ref ${QGIS_REF}..."

wget -q -O "$SETUP_SCRIPT_PATH" "$SETUP_SCRIPT_URL"
wget -q -O "$STARTUP_SCRIPT_PATH" "$STARTUP_SCRIPT_URL"

chmod +x "$SETUP_SCRIPT_PATH"
chmod +x "$STARTUP_SCRIPT_PATH"
