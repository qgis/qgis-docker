#!/usr/bin/env python3

# This scripts will output the last LTR and stable QGIS versions for Ubuntu
# Formatted as json: {"stable": "3.14.0", "ltr": "3.10.7"}

from apt_repo import APTRepository
import argparse
import re
import json

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-q', '--qgis', help='desktop or server', choices=['desktop', 'server'])
    parser.add_argument('-o', '--os', help='The operating system', choices=['ubuntu', 'debian'], default='ubuntu')
    parser.add_argument('-d', '--dist', help='The Ubuntu/Debian distribution', default='focal')
    args = parser.parse_args()
    os = args.os
    dist = args.dist

    if args.qgis == 'dekstop':
        package_name = 'qgis'
    else:
        package_name = 'qgis-server'

    data = {}
    for ltr in (True, False):
        url = 'https://qgis.org/{}{}'.format(os, '-ltr' if ltr else '')
        components = ['main']
        repo = APTRepository(url, dist, components)
        package = repo.get_packages_by_name(package_name)[0]
        assert package.package == package_name
        # https://regex101.com/r/lkuibv/2
        p = re.compile('^1:(\d(?:\.\d+)+)(?:\+\d+{})(?:\-\d+)?$'.format(dist))
        m = p.match(package.version)
        data['ltr' if ltr else 'stable'] = m.group(1)

    print(json.dumps(data))
