#!/bin/sh

log() {
   logger -s -t "mqtt" "$*"
}

export LD_LIBRARY_PATH=/var/etc/persistent/mqtt
export BIN_PATH=/etc/persistent/mqtt
export devicename=$(cat /tmp/system.cfg | grep resolv.host.1.name | sed 's/.*=\(.*\)/\1/')
export topic=homie/$devicename
export clientID="MPMQCLIENT"
export PUBBIN=$BIN_PATH/mosquitto_pub

refresh=60
version=$(cat /etc/version)-mq-0.3

source $BIN_PATH/client/mqtt.cfg

if [ -z "$mqtthost" ]; then
    echo "no host specified"
    exit 0
fi

if [ -z "$mqttusername" ] || [ -z "$mqttpassword" ]; then
    export auth=""
else
    export auth="-u $mqttusername -P $mqttpassword"
fi

# lets stop any process from former start attempts
log "killing old instances"
killall mqtask.sh
killall mqpub.sh
killall mqsub.sh
pkill -f mosquitto_sub.*$clientID
$PUBBIN -h $mqtthost $auth -t $topic/\$state -m "disconnected" -r
[ "$(basename $0)" == "mqstop.sh" ] && exit

# make our settings available to the subscripts
export mqtthost
export refresh
export percentvar
export tmpfile
export version
# identify type of mpower
export PORTS=`cat /etc/board.inc | grep feature_power | sed -e 's/.*\([0-9]\+\);/\1/'`

log "starting pub and sub scripts"
$BIN_PATH/client/mqpub.sh &
$BIN_PATH/client/mqsub.sh &