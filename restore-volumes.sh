#!/bin/bash -xe

[ "`id -u`" != '0' ] && exec sudo $0 $*

echo "This will restore some volumes directory. Take first arg is a tar ball to restore."

TAR_BALL="$1"

DOCKER_ROOT_DIR=$(docker info | grep -Po '(?<=Docker Root Dir: )[^\s]+')

mkdir $$
tar xf $TAR_BALL -C $$
cd $$

VOLUMES_DIR=$(find . -type d -name volumes)

rsync -a ${VOLUMES_DIR}/ ${DOCKER_ROOT_DIR}/volumes/

cd ../
rm -rf $$
