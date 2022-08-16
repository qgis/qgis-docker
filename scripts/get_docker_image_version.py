#!/usr/bin/env python3

# This scripts will output the QGIS versions on which LTR and stable rely on
# Formatted as json: {"stable": "3.14.0", "ltr": "3.10.7"}

import requests
import json
#import re
import argparse

url = 'https://registry.hub.docker.com/v2/repositories/opengisch/qgis-server/tags?page_size=10000'
data = requests.get(url).content.decode('utf-8')
tags = json.loads(data)['results']


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--dist', help='The Ubuntu distribution')
    #parser.add_argument('-d', '--default-dist', help='The default Ubuntu distribution, for which no suffix is in the tag')
    args = parser.parse_args()
    distro = args.dist
    #default_distro = args.default_dist

    stable_sha = None
    ltr_sha = None

    # get available tags
    availables_tags = dict()

    for tag in tags:
        if tag['name'].startswith('stable'):
            stable_sha = tag['images'][0]['digest']  # sha
        elif tag['name'].startswith('ltr'):
            ltr_sha = tag['images'][0]['digest']  # sha
        elif tag['name'].endswith(f'-{distro}'):
            availables_tags[tag['name']] = tag['images'][0]['digest']
        #elif distro == default_distro and re.match(r'^[.0-9]+$', tag['name']):
        #    availables_tags[tag['name']] = tag['images'][0]['digest']

    # determine what is ltr and stable
    stable = ""
    ltr = ""
    for tag, sha in availables_tags.items():
        if sha == stable_sha:
            stable = tag
        elif sha == ltr_sha:
            ltr = tag

    output = {'stable': stable, 'ltr': ltr}
    print(json.dumps(output))
