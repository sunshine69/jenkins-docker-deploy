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
