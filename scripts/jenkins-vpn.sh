#!/bin/bash

# This script is meant to run from jenkins run job and can be tested using commandline
# These vars get from jenkins SSM plugins. We take from command line for testing

JENKINS_VPN_PROFILE_FILE_NAME=${JENKINS_VPN_PROFILE_FILE_NAME:-$1}
JENKINS_VPN_PASSWORD=${JENKINS_VPN_PASSWORD:-$2}
JENKINS_OTP_PASSWORD=${JENKINS_OTP_PASSWORD:-$3}
JENKIN_VPN_CONTAINER_NAME=$(basename $JENKINS_VPN_PROFILE_FILE_NAME .ovpn)

echo "Container name: $JENKIN_VPN_CONTAINER_NAME"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE=${WORKSPACE:-$(dirname $SCRIPT_DIR)}
ACTION=${ACTION:-$4}
[ -z "$ACTION" ] && ACTION="start"

if [ -f /.dockerenv ]; then
    DOCKER_VOL_OPT="--volumes-from xvt_jenkins"
else
    DOCKER_VOL_OPT="-v $WORKSPACE:$WORKSPACE"
fi

start_vpn() {
    reset_count=0
    while [ $reset_count -lt 5 ]; do
	    echo "0 - Status: $vpn_status"
    	if [ "$vpn_status" != '"healthy"' ] && [ "$vpn_status" != '"starting"' ] && [ "$vpn_status" != 'completed' ]; then
    	    let "reset_count=reset_count+1"
    		OTP_CODE=$(docker run --rm --entrypoint python3 xvtsolutions/alpine-python3-aws-ansible:2.7.4 -c "import pyotp; print(pyotp.TOTP('$JENKINS_OTP_PASSWORD').now())")

    		cat <<EOF > $WORKSPACE/scripts/$JENKIN_VPN_CONTAINER_NAME.pass
jenkins
${JENKINS_VPN_PASSWORD}${OTP_CODE}
EOF
    		docker run --rm --entrypoint sed $DOCKER_VOL_OPT --workdir $WORKSPACE xvtsolutions/alpine-python3-aws-ansible:2.7.4 -i "s/auth\-user\-pass.*\$/auth-user-pass scripts\/$JENKIN_VPN_CONTAINER_NAME.pass/g" scripts/$JENKINS_VPN_PROFILE_FILE_NAME

    		vpn_status=$(docker inspect --format='{{json .State.Health.Status}}' $JENKIN_VPN_CONTAINER_NAME 2>/dev/null)
		    echo "1 - Status: $vpn_status"
    		if [ "$vpn_status" == '"healthy"' ] || [ "$vpn_status" == 'completed' ]; then
    		  echo "container already started and status is healthy"
    		else
    	          echo "Start vpn container $JENKIN_VPN_CONTAINER_NAME ..."
    		  docker rm -f $JENKIN_VPN_CONTAINER_NAME || true
    		  docker run -d --rm --name $JENKIN_VPN_CONTAINER_NAME $DOCKER_VOL_OPT --cap-add=NET_ADMIN --workdir $WORKSPACE \
    		    --device /dev/net/tun dperson/openvpn-client openvpn scripts/$JENKINS_VPN_PROFILE_FILE_NAME
    		  echo Wait 5 minutes until the vpn status is healthy
    		  c=0
    		  while [ $c -lt 60 ]; do
    		    if `docker logs --tail 5 $JENKIN_VPN_CONTAINER_NAME | grep 'Initialization Sequence Completed' >/dev/null 2>&1`; then
			        echo "Got Initialization Sequence Completed"
			        vpn_status='completed'
    		        break
    		    else
    		        if [ $c -eq 20 ]; then
    		            echo "CRITICAL ERROR. Container is not healthy after 5 minutes, aborting"
    		            docker rm -f $JENKIN_VPN_CONTAINER_NAME || true
                        break
    		        fi
    		        let "c=c+1"
    		        sleep 5
    		    fi
    		  done
    	    fi
    	else
    	    reset_count=0
    	    sleep 60
    		vpn_status=$(docker inspect --format='{{json .State.Health.Status}}' $JENKIN_VPN_CONTAINER_NAME 2>/dev/null)
    	fi
    	done
}

stop_vpn() {
      killall jenkins-vpn.sh
      docker stop $JENKIN_VPN_CONTAINER_NAME || true
      rm -f $WORKSPACE/scripts/$JENKIN_VPN_CONTAINER_NAME.pass
}

restart_vpn() {
    stop_vpn
    sleep 5
    start_vpn
}

case $ACTION in
    start)
        start_vpn;
        ;;
    stop)
        stop_vpn;
        ;;
    restart)
        restart_vpn;
        ;;
    *)
        echo "Uknown $ACTION"
        ;;
esac
