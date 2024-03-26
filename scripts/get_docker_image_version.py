#!/usr/bin/env python3

# This scripts will output the QGIS versions on which LTR and stable rely on
# Formatted as json: {"stable": "3.14.0", "ltr": "3.10.7"}

import requests
import json
import re
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-q', '--qgis', help='desktop or server', choices=['desktop', 'server'])
    parser.add_argument('-u', '--dist', help='The Ubuntu distribution')
    #parser.add_argument('-d', '--default-dist', help='The default Ubuntu distribution, for which no suffix is in the tag')
    args = parser.parse_args()
    distro = args.dist
    #default_distro = args.default_dist

    if args.qgis == 'dekstop':
        repo_name = 'qgis'
    else:
        repo_name = 'qgis-server'

    url = f'https://registry.hub.docker.com/v2/repositories/qgis/{repo_name}/tags?page_size=10000'
    data = requests.get(url).content.decode('utf-8')
    tags = json.loads(data)['results']

    stable_sha = None
    ltr_sha = None

    # get available tags
    availables_tags = dict()

    # get the full version
    match = f'^\d\.\d+\.\d+-{distro}$'

    for tag in tags:
        if tag['name'] == f'stable-{distro}':
            stable_sha = tag['images'][0]['digest']  # sha
        elif tag['name'] == f'ltr-{distro}':
            ltr_sha = tag['images'][0]['digest']  # sha
        elif re.match(match, tag['name']):
            availables_tags[tag['name']] = tag['images'][0]['digest']

    # determine what is ltr and stable
    stable = ""
    ltr = ""
    for tag, sha in availables_tags.items():
        if sha == stable_sha:
            stable = tag
            stable = stable.replace(f'-{distro}', '')
        elif sha == ltr_sha:
            ltr = tag
            ltr = ltr.replace(f'-{distro}', '')

    output = {'stable': stable, 'ltr': ltr}
    print(json.dumps(output))
