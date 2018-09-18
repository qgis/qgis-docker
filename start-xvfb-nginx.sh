#!/bin/bash

rm -f /tmp/.X99-lock
/usr/bin/Xvfb :99 -ac -screen 0 1280x1024x16 +extension GLX +render -noreset >/dev/null &
while ! pidof /usr/bin/Xvfb >/dev/null; do
    sleep 1
done
spawn-fcgi -u qgis -g qgis -d /tmp -p 9993 -- /usr/libexec/qgis/qgis_mapserv.fcgi
nginx -g "daemon off;";
