#!/usr/bin/env python3

# Smoke test of the slim image: PyQGIS, processing and GDAL Arrow/Parquet support

import tempfile
from pathlib import Path

from osgeo import gdal, ogr
from qgis.core import Qgis, QgsApplication, QgsFeature, QgsGeometry, QgsPointXY, QgsVectorLayer

for driver in ("Arrow", "Parquet"):
    assert ogr.GetDriverByName(driver), f"GDAL {driver} driver is missing"

app = QgsApplication([], False)
app.initQgis()
print(f"QGIS {Qgis.version()}, GDAL {gdal.__version__}")

import processing  # noqa: E402
from processing.core.Processing import Processing  # noqa: E402

Processing.initialize()

points = QgsVectorLayer("Point?crs=EPSG:2056&field=name:string", "points", "memory")
features = []
for i in range(3):
    feature = QgsFeature(points.fields())
    feature.setAttributes([f"point {i}"])
    feature.setGeometry(QgsGeometry.fromPointXY(QgsPointXY(2600000 + 100 * i, 1200000)))
    features.append(feature)
assert points.dataProvider().addFeatures(features)

output_dir = Path(tempfile.mkdtemp())
for extension in ("parquet", "arrow"):
    result = processing.run(
        "native:buffer",
        {"INPUT": points, "DISTANCE": 10, "OUTPUT": str(output_dir / f"buffers.{extension}")},
    )
    buffers = QgsVectorLayer(result["OUTPUT"], "buffers", "ogr")
    assert buffers.isValid(), f"{result['OUTPUT']} is not valid"
    assert buffers.featureCount() == 3, f"{result['OUTPUT']} has {buffers.featureCount()} features"
    assert buffers.dataProvider().storageType() == {"parquet": "Parquet", "arrow": "Arrow"}[extension]
    print(f"{result['OUTPUT']}: {buffers.featureCount()} features")

app.exitQgis()
