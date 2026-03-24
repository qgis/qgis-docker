#!/bin/bash
# -*- coding: utf-8 -*-
# vim: tabstop=4 shiftwidth=4 softtabstop=4
#
# oq-qgis-server
# Copyright (C) 2018-2019 GEM Foundation
#
# oq-qgis-server is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# oq-qgis-server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


cleanup() {
    # SIGTERM is propagated to children.
    # Timeout is managed directly by Docker, via it's '-t' flag:
    # if SIGTERM does not teminate the entrypoint, after the time
    # defined by '-t' (default 10 secs) the container is killed
    kill $XVFB_PID $QGIS_PID $NGINX_PID
}

waitfor() {
    # Make startup syncronous
    while ! pidof $1 >/dev/null; do
        sleep 1
    done
    pidof $1
}

trap cleanup SIGINT SIGTERM

# always convert $SKIP_NGINX to lowercase
typeset -l SKIP_NGINX

rm -f /tmp/.X99-lock
# Update font cache
fc-cache

# Generate landing page nginx config if QGIS_SERVER_LANDING_PAGE_PREFIX is set
if [ -n "${QGIS_SERVER_LANDING_PAGE_PREFIX:-}" ]; then
    PREFIX="${QGIS_SERVER_LANDING_PAGE_PREFIX}"
    # Ensure prefix starts with /
    [[ "$PREFIX" != /* ]] && PREFIX="/${PREFIX}"
    # Validate prefix to prevent config injection
    if [[ "$PREFIX" =~ ^/[a-zA-Z0-9/_-]+$ ]]; then
        cat > /etc/nginx/qgis.d/landing-page.conf <<LANDING_CONF
location ${PREFIX} {
    fastcgi_pass  localhost:9993;
    fastcgi_param SCRIPT_FILENAME /usr/lib/cgi-bin/qgis_mapserv.fcgi;
    fastcgi_param QUERY_STRING    \$query_string;
    fastcgi_param HTTPS           \$qgis_ssl;
    fastcgi_param SERVER_NAME     \$qgis_host;
    fastcgi_param SERVER_PORT     \$qgis_port;
    include fastcgi_params;
}
LANDING_CONF
        echo "Landing page nginx config generated for prefix: ${PREFIX}"
    else
        echo "WARNING: Invalid QGIS_SERVER_LANDING_PAGE_PREFIX '${PREFIX}'. Must contain only alphanumeric characters, hyphens, underscores, and forward slashes."
    fi
fi
/usr/bin/Xvfb :99 -ac -screen 0 1280x1024x16 +extension GLX +render -noreset >/dev/null &
XVFB_PID=$(waitfor /usr/bin/Xvfb)
# Do not start NGINX if environment variable '$SKIP_NGINX' is set but not '0' or 'false'
# this may be useful in production where an external reverse proxy is used
if [ -z "$SKIP_NGINX" ] || [ "$SKIP_NGINX" == "false" ] || [ "$SKIP_NGINX" == "0" ]; then
    nginx
    NGINX_PID=$(waitfor /usr/sbin/nginx)
fi
# To avoid issues with GeoPackages when scaling out QGIS should not run as root
spawn-fcgi -n -u ${QGIS_USER:-www-data} -g ${QGIS_USER:-www-data} -d ${HOME:-/var/lib/qgis} -P /run/qgis.pid -p 9993 -- /usr/lib/cgi-bin/qgis_mapserv.fcgi &
QGIS_PID=$(waitfor qgis_mapserv.fcgi)
wait $QGIS_PID
