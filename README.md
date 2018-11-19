# jenkins-docker


Contain Dockerfile for jenkins.

This repo will produce a docker image for XVT to run jenkins.

Usages
------

- Checkout this repository to a docker host you want to run jenkins
- Run the build.sh script
- Answer `y` if it asks you to stop/start `xvt_jenkins` container
- Your jenkins url would be `https://<your_jenkins_dns>:4343`

*Save all plugin list:version from existing running jenkins*

This is for use when you want to upgrade existing jenkins installation - see below - it will
auto install these plugins with correct versions.

- From running jenkins instance GUI get into `Manage Jenkins/Script Console` and run this groovy

```
Jenkins.instance.pluginManager.plugins.each{
  plugin ->
    println ("${plugin.getShortName()}:${plugin.getVersion()}")
}
```

Copy and paste the output (only first part which is the output of the println)
into the file `jenkins-plugins.list`. Save and commit into github.

*Update existing instance*

- Run `git pull` to pull the latest change from github
- Run `./build.sh` script

Agents
------

*How to make jenkins agent service on windows*
- First download the jnlp file from browser
- Right click go around and set the file type to open using javaws command. This steps may not needed
- Start cmd terminal as Admin and go to the download folder
- Run javaws -verbose <the-jnlp-file> (have to set -verbose otherwise it just exits)
- When it runs and connected, click File / Install as Service
- Quit that program
- Check in the service it should start. But for some reason we need the option -noCertificateCheck in then
- In the service findout where the java wrapper is. Get into that folder (d:\jenkins\) look at the config `jenkins-slave.xml` - edit and put that option in.

*Linux setup*
I currently did a hack by creating the below script and add a cron job to run 1 minutes each

```
#!/bin/sh

if ! ps -ef|grep -v grep | grep 'https://jenkins.xvt.technology:4343' >/dev/null 2>&1; then
echo "start jenkins agent"
cd /home/jenkins
java -jar agent.jar -jnlpUrl https://jenkins.xvt.technology:4343/computer/<NODE_NAME>/slave-agent.jnlp -secret XXXXXXXXXXXX -workDir "/var/jenkins" -noCertificateCheck &
```

Someday I can make it as fully systemd service unit file with whistle and bells but for now <shrug>
