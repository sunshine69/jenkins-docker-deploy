What is it?
==========

Scripts in this folder are run at Jenkins phisical node to setup some long
running services. Currently it is several vpn container which is used in other
jenkins container (build/deploy...) to get the network out to reach restricted
network.

- XVT utils VPN container name `vpn`
- ERRCD-WA vpn  container name `errcd-wa-vpn`

To use in your container just supply the docker run option
`--net=container:<vpn_contianer_name>` for example
`--net=container:errcd-wa-vpn`
