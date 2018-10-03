#!/bin/bash

cleanup() {
    kill $XVFB_PID $QGIS_PID
}

trap cleanup SIGINT SIGTERM

rm -f /tmp/.X99-lock
/usr/bin/Xvfb :99 -ac -screen 0 1280x1024x16 +extension GLX +render -noreset >/dev/null &
while ! pidof /usr/bin/Xvfb >/dev/null; do
    sleep 1
done
XVFB_PID=$(pidof /usr/bin/Xvfb)
spawn-fcgi -u qgis -g qgis -d /tmp -P /tmp/qgis.pid -p 9993 -- /usr/libexec/qgis/qgis_mapserv.fcgi
QGIS_PID=$(pidof /usr/libexec/qgis/qgis_mapserv.fcgi)
exec nginx -g "daemon off;";
