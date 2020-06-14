#!/usr/bin/env python3

import argparse, os, re, sys
import docker
from datetime import datetime, timedelta

parser = argparse.ArgumentParser(description='Cleaning up docker resources')

parser.add_argument('--regexp-list', '-r', metavar='[regex pattern string]', type=str, dest='regexp_list', action='append',
    default=['\:backup_for_([\d]+)$', '\:([\d]+)$' ],
    help='List of regex pattern string to filter the image to remove. It should have one capture group to extract the datetime string')

parser.add_argument('--datetime-fmt', '-df', metavar='[format string]', type=str, dest='datetime_fmt', default='%Y%m%d%H%M%S',
    help='python datetime format string to parse datetime, example %%Y, %%m etc.. This is used to parse datetime from the regex capture')

parser.add_argument('--retention-days', '-d', type=int, dest='retention_days', default=7, metavar='[days to keep]',
    help='Keep for the last of number of days')

parser.add_argument('--verbose', '-v', action='count', default=0)

args = parser.parse_args()


client = docker.from_env()
images = client.images.list()

"""
List of image object. i0.attrs =>

{'Id': 'sha256:966622f5616278a2d8a69b242f3aa8b600732a27488ff87720c8e766ecd5df1d',
 'RepoTags': ['jenkins/abb-rnd-jenkins-lts:20200521055714',
  'jenkins/abb-rnd-jenkins-lts:backup_for_20200521063438'],
 'RepoDigests': [],
 'Parent': 'sha256:60ebeaaa015e9dae4fb5154ad3e7358b6294c41665d12c5f796a189ba382803f',
 'Comment': '',
 'Created': '2020-05-21T05:57:25.956834726Z',
 'Container': '7eb304ecc52d38fe1002ab5414a1d774e1a53d569a31b47cde7abdb3bda952d2',
 'ContainerConfig': {'Hostname': '7eb304ecc52d', }
 <XXXXXX>
}
"""

# Filter ptn. Pattern has one capture group which provide a datetime string
filter_ptns = [re.compile(x) for x in args.regexp_list]

# Get a list of tuple images obj with RepoTag matches the pattern

filtered_repo_tags = []

duration = timedelta(days=args.retention_days)
now =  datetime.now()
delete_after_date = now - duration

for _img in images:
    for _tag in _img.attrs['RepoTags']:
        for ptn in filter_ptns:
            m = ptn.search(_tag)
            if m:
                if len(m.groups()) == 0:
                    if args.verbose > 0:
                        print("Date pattern does not have capture group")
                    continue
                try:
                    date_from_tag = datetime.strptime(m.group(1) ,args.datetime_fmt)
                    if date_from_tag < delete_after_date:
                        if args.verbose > 0:
                            print("Found this image tag %s suitable to mark to be removed" % _tag)
                        filtered_repo_tags.append(_tag)
                except Exception as e:
                    if args.verbose > 0:
                        print(e)

# Now we are going to remove these tags.
confirm = 'y'

if args.verbose > 0:
    confirm = input("Are you sure to remove these images? y/n: ")
    if not (confirm == 'y'):
        print("Aborted")
        sys.exit(1)

[client.images.remove(x) for x in filtered_repo_tags]

# Run cleaning up
client.containers.prune()
client.images.prune({'dangling': True})
client.images.prune_builds()
