FROM jenkins/jenkins:lts

# https://github.com/jenkinsci/docker/blob/master/README.md
# Build with command docker build -t jenkins/xvt-jenkins .
# Run like this
# docker run --detach --restart always --name jenkins -p 4343:4343 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock --add-host="gitea.xvt.technology:10.100.9.14" -v jenkins_home:/var/jenkins_home jenkins/xvt-jenkins:latest
# Status: https working

# Install sudo to allow to run sudo docker command inside.

ARG update_all=yes

USER root

RUN if [ "$update_all" = "yes" ]; then \
    apt-get update \
    && apt-get install -y sudo python-pip \
    && rm -rf /var/lib/apt/lists/*; fi

RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN if [ "$update_all" = "yes" ]; then pip install ansible awscli botocore boto3; fi

COPY docker-18.06.0-ce.tgz /tmp/docker-18.06.0-ce.tgz
RUN mkdir -p /tmp/1 && tar xzf /tmp/docker-18.06.0-ce.tgz -C /tmp/1 && mv /tmp/1/docker/* /usr/bin/ && rm -rf /tmp/1 /tmp/docker-18.06.0-ce.tgz

COPY nsre /usr/bin/nsre
 
USER jenkins

COPY xvt.technology.crt /var/lib/jenkins/cert
COPY xvt.technology.key /var/lib/jenkins/pk
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY jenkins-plugins.list /usr/share/jenkins/ref/jenkins-plugins.list 

RUN if [ "$update_all" = "yes" ]; then \
    /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/jenkins-plugins.list; fi

# These crt and key needs to supplied at docker run command.
ENV JENKINS_OPTS --httpPort=-1 --httpsPort=4343 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteArtifacts=true

ENV JAVA_OPTS -Dorg.apache.commons.jelly.tags.fmt.timeZone=Australia/Brisbane

EXPOSE 4343
