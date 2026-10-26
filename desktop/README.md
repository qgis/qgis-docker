# QGIS Desktop standalone

[![Docker Hub](https://img.shields.io/docker/pulls/qgis/qgis)](https://hub.docker.com/r/qgis/qgis)

A simple QGIS desktop Docker image, pushed on [Docker Hub](https://hub.docker.com/r/qgis/qgis).

## Python Plugin Testing

This image includes the QGIS test runner scripts for plugin testing:

- `qgis_setup.sh` — Sets up the QGIS profile for testing (creates config dirs, disables tips, optionally enables and links a plugin)
- `qgis_startup.py` — Disables modal error dialogs in favour of console output
- `qgis_testrunner.sh` / `qgis_testrunner.py` — Runs Python unit tests inside a QGIS instance

### Example usage

```bash
PLUGIN_NAME=my_plugin  # the sub-directory containing plugin sources

# Start a container mapping your repo to /tests_directory
docker run -dt --name qgis \
  -v "${PWD}:/tests_directory" \
  -e QT_QPA_PLATFORM=offscreen \
  qgis/qgis:latest

# Set up QGIS for testing and enable the plugin
docker exec qgis bash -c "qgis_setup.sh ${PLUGIN_NAME}"

# Run your tests (example with unittest discover)
docker exec qgis bash -c "cd /tests_directory && python3 -m pytest"

# Or use the built-in test runner (runs tests inside a real QGIS instance)
docker exec qgis bash -c "qgis_testrunner.sh ${PLUGIN_NAME}.tests.run_all"

# Clean up
docker rm -f qgis
```

> **Note:** The plugin source directory must be accessible at `/tests_directory/<PLUGIN_NAME>` inside the container.
> `qgis_setup.sh` will symlink it into the QGIS plugins folder automatically.
