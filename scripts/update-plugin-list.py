#!/usr/bin/env python3

import json, requests, sys

"""
Get the currentl plugin list from the running jenkins instance and save it to
the text file jenkins-plugins.list so the build jenkins image will
automatically install these plugins with current version.

Usage: $0 <jenkins_api_url> <output_file_path>
"""

try:
    output_file_name = sys.argv[2]
    if output_file_name == '':
        print("output_file_name can not be empty.")
        sys.exit(1)
except:
    print("output_file_name required.")
    sys.exit(1)

JENKINS_API_URL = "{jenkins_url}/pluginManager/api/json?depth=1".format(jenkins_url=sys.argv[1])

data = requests.get(JENKINS_API_URL)

print(data.status_code)
if data.status_code != 200:
    print("error contacting jenkins api url")
    print(data)
    sys.exit(1)

data_json = data.json()
plugin_data = data_json['plugins']

# sort by the value of the key 'shortName'
sorted_plugin_data = sorted(plugin_data, key=lambda k: k['shortName'])

out_text = "\n".join(["%s:%s" % (x['shortName'], x['version']) for x in sorted_plugin_data])

open(output_file_name, 'w').write(out_text)
