#!/bin/bash -xe

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CERT_DOMAIN={{ cert_domain }}

cd $SCRIPT_DIR

if [ -z "$BUILD_NUMBER" ]; then
    export BUILD_NUMBER="$(date '+%Y%m%d%H%M%S')"
fi

if [ "$1" = "update-cert" ]; then
    update_all=no
    KEY_PASSPHRASE="$2"
    [ -z "$KEY_PASSPHRASE" ] && echo "Key passpharse required" && exit 1
    docker tag jenkins/{{ jenkins_image_name }}:latest jenkins/{{ jenkins_image_name }}:backup_for_${BUILD_NUMBER} || true
    docker build -t jenkins/{{ jenkins_image_name }}:${BUILD_NUMBER} --build-arg KEY_PASSPHRASE=$KEY_PASSPHRASE -f Dockerfile.update-cert .
    docker tag jenkins/{{ jenkins_image_name }}:${BUILD_NUMBER} jenkins/{{ jenkins_image_name }}:latest
else
    echo "Update jenkins? y/n"
    read ans
    if [ "$ans" != "y" ]; then
        echo "Aborted. If you only want to update the SSL cert run $0 update-cert"
        exit 1
    else
        update_all=yes
        KEY_PASSPHRASE="$1"
        [ -z "$KEY_PASSPHRASE" ] && echo "Key passpharse required" && exit 1

        echo "Pull the current plugin list and update? Say n if this is the first time deployment. y/n"
        read confirm
        if [ "$confirm" = "y" ]; then
            ${SCRIPT_DIR}/scripts/update-plugin-list.py 'https://{{ jenkins_api_user }}:{{ jenkins_api_token }}@{{ cert_domain }}:{{ jenkins_port }}' \
                ${SCRIPT_DIR}/jenkins-plugins.list || (echo "Error updating plugin list, aborting" && exit 1)
        fi

        docker pull jenkins/jenkins:lts
        docker tag jenkins/{{ jenkins_image_name }}:latest jenkins/{{ jenkins_image_name }}:backup_for_${BUILD_NUMBER} || true
	    SOCK_DOCKER_GID=$(grep docker /etc/group | cut -f3 -d':')
        docker build -t jenkins/{{ jenkins_image_name }}:${BUILD_NUMBER} --build-arg update_all=$update_all \
            --build-arg SOCK_DOCKER_GID=$SOCK_DOCKER_GID --build-arg KEY_PASSPHRASE=$KEY_PASSPHRASE .
        docker tag jenkins/{{ jenkins_image_name }}:${BUILD_NUMBER} jenkins/{{ jenkins_image_name }}:latest
    fi
fi

printf "\nIf the first time build you need to switch to other console run docker logs -f {{ jenkins_image_name }} to find out the jenkins admin hash. Then access the web interface to complete the setup."

echo "Stop and start jenkins container? y/n"
read ans
if [ "$ans" = 'y' ]; then
    docker stop {{ jenkins_image_name }} || true
    docker rm {{ jenkins_image_name }} || true
    docker run --detach --restart always --name {{ jenkins_image_name }} \
        -p {{ jenkins_port|default(8080) }}:{{ jenkins_port|default(8080) }} \
        -p {{ jenkins_agent_port|default(50000) }}:{{ jenkins_agent_port|default(50000) }} \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v jenkins_home:/var/jenkins_home {{ docker_run_extra_opts|default('') }} \
        jenkins/{{ jenkins_image_name }}:latest
fi
