#!/bin/bash -xe

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $SCRIPT_DIR

if [ "$1" == 'update-cert' ]; then
    TEST_UPADTE=$(wget https://xvt-public-repo.s3-ap-southeast-2.amazonaws.com/pub/certs/jenkins.xvt.technology.state -O -)
    echo $TEST_UPADTE
    if [ "$TEST_UPADTE" != 'NEED-UPDATE' ]; then
        exit 0
    fi
fi

if [ ! -f docker-18.06.0-ce.tgz ]; then
    wget -q https://s3-ap-southeast-2.amazonaws.com/xvt-public-repo/pub/docker-18.06.0-ce.tgz
fi

#XVT_KEY_PASS=$(aws ssm get-parameter --name "/xvt-certificates-mngt/xvt.technology.PASSPHRASE" --with-decryption --region ap-southeast-2 | grep -oP '(?<="Value": ")[^"]+(?=".*)')

if [ -z "$XVT_CERTIFICATES_MNGT_XVT_TECHNOLOGY_PASSPHRASE" ]; then
    XVT_CERTIFICATES_MNGT_XVT_TECHNOLOGY_PASSPHRASE=$(cat ~/.XVT_KEY_PASS)
fi

wget https://xvt-public-repo.s3-ap-southeast-2.amazonaws.com/pub/certs/xvt.technology-encrypted.key -O xvt.technology-encrypted.key
wget https://xvt-public-repo.s3-ap-southeast-2.amazonaws.com/pub/certs/xvt.technology-chained.crt -O xvt.technology.crt

openssl rsa -passin pass:${XVT_CERTIFICATES_MNGT_XVT_TECHNOLOGY_PASSPHRASE} -in xvt.technology-encrypted.key -out xvt.technology.key

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
    docker run --detach --restart always --name xvt_jenkins -p 4343:4343 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v /dev/net/tun:/dev/net/tun --add-host="docker-host.xvt.internal:10.100.9.14" -v jenkins_home:/var/jenkins_home jenkins/xvt-jenkins:latest

    echo 'UP-TO-DATE' > /tmp/jenkins.xvt.technology.state
    aws s3 cp /tmp/jenkins.xvt.technology.state s3://xvt-public-repo/pub/certs/jenkins.xvt.technology.state --profile xvt-public-repo
    rm -f /tmp/jenkins.xvt.technology.state

fi
