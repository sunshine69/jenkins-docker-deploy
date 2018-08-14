#!/bin/bash

if [ ! -f docker-18.06.0-ce.tgz ]; then
    wget https://s3-ap-southeast-2.amazonaws.com/xvt-public-repo/pub/docker-18.06.0-ce.tgz
fi

if [ -f xvt.technology.key ]; then
    echo "TODO Need to implement s3 get the key and crt file here"
fi

docker build -t jenkins/xvt-jenkins .
