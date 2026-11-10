#!/usr/bin/env python3

# Smoke test of the slim images: PyQGIS and GDAL Arrow/Parquet support, and processing.
# With --core, for the image built without the gui library: qgis.utils instead of processing.

import sys
import tempfile
from pathlib import Path

from osgeo import gdal, ogr
from qgis.core import (
    Qgis,
    QgsApplication,
    QgsCoordinateTransformContext,
    QgsFeature,
    QgsGeometry,
    QgsPointXY,
    QgsVectorFileWriter,
    QgsVectorLayer,
)

CORE = "--core" in sys.argv[1:]
DRIVERS = {"parquet": "Parquet", "arrow": "Arrow"}

for driver in DRIVERS.values():
    assert ogr.GetDriverByName(driver), f"GDAL {driver} driver is missing"

app = QgsApplication([], False)
app.initQgis()
print(f"QGIS {Qgis.version()}, GDAL {gdal.__version__}")

points = QgsVectorLayer("Point?crs=EPSG:2056&field=name:string", "points", "memory")
features = []
for i in range(3):
    feature = QgsFeature(points.fields())
    feature.setAttributes([f"point {i}"])
    feature.setGeometry(QgsGeometry.fromPointXY(QgsPointXY(2600000 + 100 * i, 1200000)))
    features.append(feature)
assert points.dataProvider().addFeatures(features)

output_dir = Path(tempfile.mkdtemp())

if CORE:
    # QGIS Server loads its Python plugins with qgis.utils, which must not require the gui library
    import qgis.utils  # noqa: E402, F401

    try:
        import qgis.gui  # noqa: F401
    except ImportError:
        pass
    else:
        raise AssertionError("qgis.gui is available")

    def write(extension):
        options = QgsVectorFileWriter.SaveVectorOptions()
        options.driverName = DRIVERS[extension]
        path = str(output_dir / f"points.{extension}")
        error, message, _, _ = QgsVectorFileWriter.writeAsVectorFormatV3(
            points, path, QgsCoordinateTransformContext(), options
        )
        assert error == QgsVectorFileWriter.WriterError.NoError, message
        return path

else:
    import processing  # noqa: E402
    from processing.core.Processing import Processing  # noqa: E402

    Processing.initialize()

    def write(extension):
        result = processing.run(
            "native:buffer",
            {"INPUT": points, "DISTANCE": 10, "OUTPUT": str(output_dir / f"buffers.{extension}")},
        )
        return result["OUTPUT"]


for extension in DRIVERS:
    path = write(extension)
    layer = QgsVectorLayer(path, extension, "ogr")
    assert layer.isValid(), f"{path} is not valid"
    assert layer.featureCount() == 3, f"{path} has {layer.featureCount()} features"
    assert layer.dataProvider().storageType() == DRIVERS[extension]
    print(f"{path}: {layer.featureCount()} features")

app.exitQgis()
