#!/usr/bin/env python3

# This scripts will output the QGIS versions on which LTR and stable rely on
# Formatted as json: {"stable": "3.14.0", "ltr": "3.10.7"}

import requests
import json

url = 'https://registry.hub.docker.com/v2/repositories/opengisch/qgis-server/tags?page_size=10000'
data = requests.get(url).content.decode('utf-8')
tags = json.loads(data)['results']

# get available tags
availables_tags = {}
for tag in tags:
    if not tag['name'].endswith('-ubuntu'):
        continue
    if tag['name'].startswith('stable'):
        stable = tag['images'][0]['digest']  # sha
    elif tag['name'].startswith('ltr'):
        ltr = tag['images'][0]['digest']  # sha
    else:
        tag_name = tag['name'].strip('-ubuntu')
        availables_tags[tag_name] = tag['images'][0]['digest']

# determine what is ltr and stable
for tag, sha in availables_tags.items():
    if sha == stable:
        stable = tag
    elif sha == ltr:
        ltr = tag

output = {'stable': stable, 'ltr': ltr}
print(json.dumps(output))
