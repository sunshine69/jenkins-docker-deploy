# jenkins-docker


Contain Dockerfile for jenkins.

This project will produce a docker image for to run jenkins.

It will guide a simple deployment and maintain your jenkins instance. For more information please take a look at
the playbooks.

Usages
------

*First deploy*

*Configure the host*

- Get your jenkins host a proper DNS. 
    - If you want to use duckdns.org with letsencrypt go to the letsencrypt section below and comes back
    - If not then you need to handle the key yourself manually. The output is
      that you need to create a javakeystore format names `jenkins.jks` which
      contains your key and having a passphrase known to you.

Assume you already prepare the your host inventory and commit to the repo like below:

- Get the this repo 
- Add your new jenkins host into the inventory file `ansible/inventory/hosts` in the `jenkins_hosts` host group
  The host inventory name must be the same as current jenkins host name
- Add your inventory data of your host to `ansible/inventory/host_vars/<you  hostname>.yaml`
  You can use the existing one as template and copy over. Update  these
  variables. To get the vaulted string use ansible command like below, you need
  to generate a vault password for your host.

```
read -s $p
# Enter your password
ansible-vault encrypt_string "$p"
```

then copy and paste the output to your inventory file.

Contact the RnD team, they are happy to assit you with these.

Then...

- ssh into the host you want to convert it into jenkins 
- install git manually
- checkout this repo

```
git clone git@github.com:Mincom/pges-devops.git
cd pges-devops 
# when it merged the branch will change to master
git checkout -b adding-jenkins-docker origin/adding-jenkins-docker
```

- Create the vault file in your home directory. This is a normal file with
  permission 0600 contains the ansible vault password string that you used to
  encrypt your inventory variables in the previous steps.
  The file localtion should be `~/.ansible/jenkins-docker-vault`

*Set up the host*

- If you use your own ssl key please do whatever you need to do to generate a java keystore file named
  `jenkins.jks` in the current directory (same as the build.sh script). You would have know the `key_passphrase`
  please encrypt it using ansible-vault and update to your own host inventory. Then run:

```
cd ansible
# Install ansible manually depends on os. Or using pip generically but then you need to install python3-pip
# manually
pip3 install ansible
ansible-playbook jenkins-host.yaml
```

- If you use letsencrypt domain with duckdns.org then run (this will include the setup host playbook
  automatically)

```
cd ansible
ansible-playbook letsencrypt/play.yaml
```    

It would request for the key, certs and deploy a corn task to auto update the letsencrypt cert.

After that you should have the script `build.sh` and two docker files `Dockerfile, Dockerfile.update-cert` in
the current directory which from now we will use it to deploy jenkins container or update it.

To know what is your <your javakeystore passphrase> from ansible inventory
run script `display-info.sh` in the `ansible` directory.


The passphrase is used when you run the build.sh.

*Run script to actually deploy the jenkins_container*

- Run the `build.sh <your javakeystore passphrase>` script. Use shell read command for the pass to be sure it is
  not in history.
- Answer `y` if it asks you to stop/start `XXX` container
- Your jenkins url would be `https://<your_jenkins_dns>:<your jenkins_port>`


From now on you only need to

*Update existing instance*

This is when you get the jenkins notify that new jenkins version is available and you want to update the
instance.

- Change to the check out directory.
- At root directory level run `git pull` to pull the latest change from github
- Run `read -s p ; ./build.sh "$p"` script. Enter your keystore password at the prompt.


*Save all plugin list:version from existing running jenkins*

Do so if you want the list of plugin to be saved in git repo so you can move the jenkins to a new server. 
For existing the `build.sh` script has the ability to update automatically if you setup the `jenkins_api_user` 
and `jenkins_api_token` var. Use jenkins web gui to create the user and geenrate the token. Then encrypt it 
using `ansible-vault encrypt_string` command - cope paste it to your host inventory in `host_vars` dir.

- From running jenkins instance GUI get into `Manage Jenkins/Script Console` and run this groovy

```
Jenkins.instance.pluginManager.plugins.each{
  plugin ->
    println ("${plugin.getShortName()}:${plugin.getVersion()}")
}
```

Copy and paste the output (only first part which is the output of the println)
into the file `jenkins-plugins.list`. Save and commit into github.



*Update certificate only*

If your certificate expired (handle manually case) then you need to re-generate the java keystore `jenkins.jks`
with your new certificates pair. Then run this:

```
./build.sh update-cert <java_keystore_key_passphrase>
```

Emergency - Backup
------------------

For everytime we update the `build.sh` script will tag the current running image to have the tag
`backup_for_XXX`. Run `docker images` to examine. The XXX is timestamp of the time we run update.

If in case the update failed all you need to do is to re-tag that docker image latest back to the backup. And
then start docker manually using that latest or just run the updat-cert (even you are not updat cert - it just
does no harm)

```
./build.sh update-cert <java_keystore_key_passphrase>
```

There is a script to clean dangling docker images. I will add a clean up too old images later on (TODO)

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

if ! ps -ef|grep -v grep | grep 'https://<your_domain>:8080' >/dev/null 2>&1; then
echo "start jenkins agent"
cd /home/jenkins
java -jar agent.jar -jnlpUrl https://<your domain>:8080/computer/<NODE_NAME>/slave-agent.jnlp -secret XXXXXXXXXXXX -workDir "/var/jenkins" -noCertificateCheck &
```

Someday I can make it as fully systemd service unit file with whistle and bells but for now <shrug>

Letsencrypt and duckdns.org
---------------------------

- Register a domain with `duckdns.org` manually. After that process you have a name and a account token
- Add your new jenkins host into the inventory file and in the `jenkins_hosts` host group.
- Add your inventory data of your host to `inventory/host_vars/<you  hostname>.yaml`. 
  You can use the existing one as template and copy over. Update  these
  variables. To get the vaulted string use ansible command like below, you need
  to generate a vault password for your host.
  
  You should choose the key_passphrase at first, encrypt using ansible vault and paste into it. This is used
  when we run the build.sh later on and used to encrypt private keys, javakeystore.

```
ansible-vault encrypt_string '<your password>'
```

then copy and paste the output to your inventory file.
