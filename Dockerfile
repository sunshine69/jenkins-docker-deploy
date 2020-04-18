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

RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
    echo "docker:x:135:jenkins" >> /etc/group

RUN if [ "$update_all" = "yes" ]; then pip install ansible awscli botocore boto3; fi

COPY docker-18.06.0-ce.tgz /tmp/docker-18.06.0-ce.tgz
RUN mkdir -p /tmp/1 && tar xzf /tmp/docker-18.06.0-ce.tgz -C /tmp/1 && mv /tmp/1/docker/* /usr/bin/ && rm -rf /tmp/1 /tmp/docker-18.06.0-ce.tgz

COPY nsre /usr/bin/nsre

COPY helm /usr/local/bin/helm
 
USER jenkins

#ARG CERT_FILE=inxuanthuy.com.crt
#ARG KEY_FILE=inxuanthuy.com.key

# Remember jenkins does not like private key - it only accept rsa key. Thus you
# may need to convert it using openssl command - like openssl rsa -in
# private_key -out your-rsa-key

# Update: Have to switch to use java keystore as the old way - it does not send
# the whole certificate chain thus gitea or any client does not support auto
# certificate discovery wont accept it.
# Use keytool and openssl to convert
# openssl pkcs12 -inkey inxuanthuy.com.key -in inxuanthuy.com.crt -export -out inxuanthuy.com.pkcs12
# keytool -importkeystore -srckeystore inxuanthuy.com.pkcs12 -srcstoretype pkcs12 -destkeystore jenkins.jks
#Or a batch mode (again f*** u keytool always ask for source password

# openssl pkcs12 -inkey inxuanthuy.com.key -in inxuanthuy.com.crt -export -passout pass:1q2w3e -out inxuanthuy.com.pkcs12
# echo 1q2w3e|keytool -importkeystore -srckeystore inxuanthuy.com.pkcs12 -srcstoretype pkcs12 -storepass 1q2w3e -destkeystore jenkins.jks -noprompt


#COPY --chown=jenkins:jenkins ${CERT_FILE} /var/lib/jenkins/cert
#COPY --chown=jenkins:jenkins ${KEY_FILE} /var/lib/jenkins/pk
COPY --chown=jenkins:jenkins jenkins.jks /var/lib/jenkins/jenkins.jks

COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY jenkins-plugins.list /usr/share/jenkins/ref/jenkins-plugins.list 

RUN if [ "$update_all" = "yes" ]; then \
    /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/jenkins-plugins.list; fi

# These crt and key needs to supplied at docker run command.
#ENV JENKINS_OPTS --httpPort=-1 --httpsPort=4343 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteArtifacts=true
ENV JENKINS_OPTS --httpPort=-1 --httpsPort=4343 --httpsKeyStore=/var/lib/jenkins/jenkins.jks --httpsKeyStorePassword=1q2w3e -Dio.jenkins.plugins.artifact_manager_jclouds.s3.S3BlobStoreConfig.deleteArtifacts=true

ENV JAVA_OPTS -Dorg.apache.commons.jelly.tags.fmt.timeZone=Australia/Brisbane

EXPOSE 4343
