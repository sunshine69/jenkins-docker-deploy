#!/bin/bash

echo "This script will backup all docker volumes that are used by the container into a tarball."
echo
echo "You can restore it in the new server you run if you want to move the deployment into another server"

[ "`id -u`" != '0' ] && exec sudo $0

SERVICE_NAME=jenkins_home

DIR_LIST=`for vol_name in $(docker volume ls | grep $SERVICE_NAME | awk '{print $2}'); do docker volume inspect $vol_name | grep -Po '(?<="Mountpoint": ")[^"]+(?=")' ; done`

echo "Creating the tar archieve ${SERVICE_NAME}-docker-vol-backup.tgz ..."
tar czf ${SERVICE_NAME}-docker-vol-backup.tgz $DIR_LIST
