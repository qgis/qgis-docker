# QGIS Desktop standalone

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis)](https://hub.docker.com/r/qgis/qgis)

A simple QGIS desktop Docker image, pushed on [Docker Hub](https://hub.docker.com/r/qgis/qgis).

## Python Plugin testing

This image can be used to set up a testing environment for plugins, e.g.

```
PLUGIN_DIR=<plugin_name> # e.g. PLUGIN_NAME=valhalla

# it's important to map the plugin's root to /tests_directory and that $PLUGIN_DIR is the sub-directory containing the plugin sources
docker run -dt --name qgis -v ${PWD}:/tests_directory -e QT_QPA_PLATFORM="offscreen" qgis/qgis:latest

# run the qgis_setup.sh script and then your tests, e.g.
docker exec qgis bash -c "qgis_setup.sh ${PLUGIN_DIR}"

# now you can run whatever you need
docker exec qgis bash -c "apt-get update && apt-get install -y pre-commit python3-coverage"
docker exec qgis bash -c "git config --global --add safe.directory /tests_directory"
docker exec qgis bash -c "cd /tests_directory && pre-commit run --all-files"
docker exec qgis bash -c "cd /tests_directory && python3 -m coverage run -m unittest discover"
docker exec qgis bash -c "cd /tests_directory && python3 -m coverage report"
docker exec qgis bash -c "cd /tests_directory && python3 -m coverage lcov --include "${PLUGIN_DIR}/*""
```
