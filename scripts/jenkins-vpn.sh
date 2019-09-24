#!/bin/sh -x

# Run from root cron job like this
# /home/ubuntu/src/xvt-jenkins/scripts/jenkins-vpn.sh errcd-wa.ovpn <PIN> <OTP_PASS>
# It will start a openvpn container to connect to the vpn
# The other container can use the network using docker option --net=container:<container_name>

JENKINS_VPN_PROFILE_FILE_NAME=${JENKINS_VPN_PROFILE_FILE_NAME:-$1}
JENKINS_VPN_USERNAME=${JENKINS_OTP_PASSWORD:-$2}
JENKINS_VPN_PASSWORD=${JENKINS_VPN_PASSWORD:-$3}
JENKINS_OTP_PASSWORD=${JENKINS_OTP_PASSWORD:-$4}

JENKIN_VPN_CONTAINER_NAME=$(basename $JENKINS_VPN_PROFILE_FILE_NAME .ovpn)
# Quit if there is one script already running
[ -f "/tmp/$JENKIN_VPN_CONTAINER_NAME" ] && exit 0

echo "Container name: $JENKIN_VPN_CONTAINER_NAME"
touch /tmp/$JENKIN_VPN_CONTAINER_NAME
trap "rm -f /tmp/$JENKIN_VPN_CONTAINER_NAME" EXIT

vpn_status=$(docker inspect --format='{{json .State.Status}}' $JENKIN_VPN_CONTAINER_NAME 2>/dev/null)
echo $vpn_status

if [ "$vpn_status" = '"exited"' ]; then
    echo "Cleanup old stale CT"
    docker rm -f $JENKIN_VPN_CONTAINER_NAME
fi


SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKSPACE=${WORKSPACE:-$(dirname $SCRIPT_DIR)}
ACTION=${ACTION:-$5}
[ -z "$ACTION" ] && ACTION="start"

if [ -f "/.dockerenv" ]; then
    DOCKER_VOL_OPT="--volumes-from xvt_jenkins"
else
    DOCKER_VOL_OPT="-v ${WORKSPACE}:${WORKSPACE}"
fi

start_vpn() {
    reset_count=0
    while [ $reset_count -lt 5 ]; do
        echo "0 - Status: $vpn_status"
    if [ "$vpn_status" != '"healthy"' ] && [ "$vpn_status" != '"starting"' ] && [ "$vpn_status" != 'completed' ]; then
        reset_count=$((reset_count+1))
        if [ ! -z "$JENKINS_OTP_PASSWORD" ]; then
        OTP_CODE=$(docker run --rm --entrypoint python3 xvtsolutions/alpine-python3-aws-ansible:2.8.4 -c "import pyotp; print(pyotp.TOTP('$JENKINS_OTP_PASSWORD').now())")
        else
            OTP_CODE=''
        fi

        cat <<EOF > $WORKSPACE/scripts/$JENKIN_VPN_CONTAINER_NAME.pass
$JENKINS_VPN_USERNAME
${JENKINS_VPN_PASSWORD}${OTP_CODE}
EOF
        docker run --rm --entrypoint sed $DOCKER_VOL_OPT --workdir $WORKSPACE xvtsolutions/alpine-python3-aws-ansible:2.8.1 -i "s/auth\-user\-pass.*\$/auth-user-pass scripts\/$JENKIN_VPN_CONTAINER_NAME.pass/g" scripts/$JENKINS_VPN_PROFILE_FILE_NAME

        vpn_status=$(docker inspect --format='{{json .State.Health.Status}}' $JENKIN_VPN_CONTAINER_NAME 2>/dev/null)
        echo "1 - Status: $vpn_status"
        if [ "$vpn_status" = '"healthy"' ] || [ "$vpn_status" = 'completed' ]; then
          echo "container already started and status is healthy"
        else
          echo "Start vpn container $JENKIN_VPN_CONTAINER_NAME ..."
              docker rm -f $JENKIN_VPN_CONTAINER_NAME || true
              docker run -d --name $JENKIN_VPN_CONTAINER_NAME $DOCKER_VOL_OPT \
                --cap-add=NET_ADMIN --workdir $WORKSPACE \
            --device /dev/net/tun dperson/openvpn-client \
                openvpn scripts/$JENKINS_VPN_PROFILE_FILE_NAME

          echo Wait maximum 5 minutes until the vpn status is healthy
          c=0
          while [ $c -lt 60 ]; do
            vpn_status=$(docker inspect --format='{{json .State.Health.Status}}' $JENKIN_VPN_CONTAINER_NAME 2>/dev/null)
            if [ "$vpn_status" = '"healthy"' ]; then
                echo "Got Initialization Sequence Completed"
                vpn_status='completed'
            break
            else
            if [ $c -ge 20 ]; then
                echo "CRITICAL ERROR. Container is not healthy after 5 minutes, aborting"
                docker rm -f $JENKIN_VPN_CONTAINER_NAME || true
                            break
            fi
            c=$((c+1))
            sleep 5
            fi
          done
        fi
    else
        reset_count=100
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
