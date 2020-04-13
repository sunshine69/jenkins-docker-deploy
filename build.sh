#!/bin/bash -xe

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CERT_DOMAIN=inxuanthuy.com
CERT_STATE_URL="https://note.inxuanthuy.com:6919/view?id=1704&t=3"
WEB_RESOURCE_URL="https://act2-prod-infra-build.s3-ap-southeast-2.amazonaws.com/pub/devops"


cd $SCRIPT_DIR

if [ ! -f docker-18.06.0-ce.tgz ]; then
    wget -q "${WEB_RESOURCE_URL}/docker-18.06.0-ce.tgz"
fi

wget "${WEB_RESOURCE_URL}/nsre-linux-amd64-static" -O nsre
chmod +x nsre

sudo cp /etc/ssl/${CERT_DOMAIN}.* .

if [ "$1" = "update-cert" ]; then
    STATUS=$(wget $CERT_STATE_URL -O -)
    [ "x$STATUS" != "xNEED-UPDATE" ] && echo "Certs status is $STATUS. Do nothing" && exit 0
    echo "You need to copy the up-ro-date cert manually into this dir $(pwd). When done hit enter."
    read _junk
    echo 'UP-TO-DATE' > /tmp/jenkins.${CERT_DOMAIN}.state
    #aws s3 cp /tmp/jenkins.${CERT_DOMAIN}.state s3://xvt-public-repo/pub/certs/jenkins.${CERT_DOMAIN}.state --profile xvt-public-repo
    echo "You need to update the cert status file manually. The URL is $CERT_STATE_URL. Hit enter to continue"
    read junk_
    rm -f /tmp/jenkins.${CERT_DOMAIN}.state
    update_all=no
else
    echo "Update jenkins? y/n"
    read ans
    [ "$ans" != "y" ] && echo "Aborted by user" && exit 1
    update_all=yes
    docker pull jenkins/jenkins:lts
fi

if [ -z "$BUILD_NUMBER" ]; then
    export BUILD_NUMBER="$(date '+%Y%m%d%H%M%S')"
fi

docker tag jenkins/xvt-jenkins:latest jenkins/xvt-jenkins:backup_for_${BUILD_NUMBER}
docker build -t jenkins/xvt-jenkins:${BUILD_NUMBER} --build-arg update_all=$update_all .
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
# docker-host.xvt.internal is the host having the dockerd run. Inside the jenkins container if we need to run docker container we will use this docker host name and IP.
        --add-host="docker-host.xvt.internal:10.100.9.95" jenkins/xvt-jenkins:latest
fi
