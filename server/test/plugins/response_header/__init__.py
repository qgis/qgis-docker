# QGIS Server plugin adding a header to the responses, to test that the Python plugins are loaded

from qgis.server import QgsServerFilter


class ResponseHeaderFilter(QgsServerFilter):
    def onResponseComplete(self):
        self.serverInterface().requestHandler().setResponseHeader("X-QGIS-Test-Plugin", "loaded")
        return True


class ResponseHeaderPlugin:
    def __init__(self, server_iface):
        server_iface.registerFilter(ResponseHeaderFilter(server_iface), 100)


def serverClassFactory(server_iface):
    return ResponseHeaderPlugin(server_iface)
