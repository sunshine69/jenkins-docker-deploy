#!/bin/bash -xe

if [ ! -f docker-18.06.0-ce.tgz ]; then
    wget -q https://s3-ap-southeast-2.amazonaws.com/xvt-public-repo/pub/docker-18.06.0-ce.tgz
fi

aws s3 cp s3://xvt-aws-secure-backups/jenkins/xvt.technology.key .
aws s3 cp s3://xvt-aws-secure-backups/jenkins/xvt.technology.crt .

if [ -z "$BUILD_NUMBER" ]; then
    export BUILD_NUMBER="$(date '+%Y%m%d%H%M%S')"
fi

docker pull jenkins/jenkins:lts
docker build -t jenkins/xvt-jenkins:${BUILD_NUMBER} .
docker tag jenkins/xvt-jenkins:${BUILD_NUMBER} jenkins/xvt-jenkins:latest

echo "Stop and start jenkins container? y/n"
read ans
if [ "$ans" = 'y' ]; then
    docker stop xvt_jenkins || true
    docker rm xvt_jenkins || true
    docker run --detach --restart always --name xvt_jenkins -p 4343:4343 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock --add-host="gitea.xvt.technology:10.100.9.14" -v jenkins_home:/var/jenkins_home jenkins/xvt-jenkins:latest
fi
