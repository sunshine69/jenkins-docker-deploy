What is it?
==========

Scripts in this folder are run at Jenkins physical node to setup some long
running services. Currently it is several vpn container which is used in other
jenkins container (build/deploy...) to get the network out to reach restricted
network.

- XVT utils VPN container name `vpn`
- ERRCD-WA vpn  container name `errcd-wa-vpn`

To use in your container just supply the docker run option
`--net=container:<vpn_container_name>` for example
`--net=container:errcd-wa-vpn`

If you run your project on another agent box rather than `master` and if you require vpn access and the vpn is not setup there you may need to run this script as a preparation stage for your build. You need to populate these variables into SSM and use SSM jenkins plugins to feth them.

```
JENKINS_VPN_PROFILE_FILE_NAME=
JENKINS_VPN_PASSWORD=
JENKINS_OTP_PASSWORD=
JENKIN_VPN_CONTAINER_NAME=
```

JENKINS_VPN_PROFILE_FILE_NAME is the filename of the vpn profile. Setup the user in the corresponding pritunl and get these information.
