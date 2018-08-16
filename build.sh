#!/bin/bash -x

if [ ! -f docker-18.06.0-ce.tgz ]; then
    wget -q https://s3-ap-southeast-2.amazonaws.com/xvt-public-repo/pub/docker-18.06.0-ce.tgz
fi

aws s3 cp s3://xvt-aws-secure-backups/jenkins/xvt.technology.key .
aws s3 cp s3://xvt-aws-secure-backups/jenkins/xvt.technology.crt .

if [ -z "$BUILD_NUMBER" ]; then
    export BUILD_NUMBER="$(date '+%Y%m%d%H%M%S')"
fi

docker build -t jenkins/xvt-jenkins:${BUILD_NUMBER} .
