#!/bin/bash -xe

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $SCRIPT_DIR

if [ ! -f docker-18.06.0-ce.tgz ]; then
    wget -q https://s3-ap-southeast-2.amazonaws.com/xvt-public-repo/pub/docker-18.06.0-ce.tgz
fi

if [ -z "$BUILD_NUMBER" ]; then
    export BUILD_NUMBER="$(date '+%Y%m%d%H%M%S')"
fi

sudo cp /etc/ssl/xvt.technology.* .

docker pull jenkins/jenkins:lts
docker build -t jenkins/xvt-jenkins:${BUILD_NUMBER} .
docker tag jenkins/xvt-jenkins:${BUILD_NUMBER} jenkins/xvt-jenkins:latest

echo "Stop and start jenkins container? y/n"
read ans
if [ "$ans" = 'y' ]; then
    docker stop xvt_jenkins || true
    docker rm xvt_jenkins || true
    docker run --detach --restart always --name xvt_jenkins -p 4343:4343 -p 50000:50000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /dev/net/tun:/dev/net/tun \
        -v jenkins_home:/var/jenkins_home \
        --add-host="docker-host.xvt.internal:10.100.9.95" jenkins/xvt-jenkins:latest

    echo 'UP-TO-DATE' > /tmp/jenkins.xvt.technology.state
    aws s3 cp /tmp/jenkins.xvt.technology.state s3://xvt-public-repo/pub/certs/jenkins.xvt.technology.state --profile xvt-public-repo
    rm -f /tmp/jenkins.xvt.technology.state

fi
