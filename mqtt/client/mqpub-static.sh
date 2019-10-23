#!/bin/sh
# homie spec 4.0.0 (complete)
$PUBBIN -h $mqtthost $auth -t $topic/\$state -m "init" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$homie -m "4.0.0" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$name -m "$devicename" -r

NODES=`seq $PORTS | sed 's/\([0-9]\)/port\1/' |  tr '\n' , | sed 's/.$//'`
$PUBBIN -h $mqtthost $auth -t $topic/\$nodes -m "$NODES" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$extensions -m "" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$implementation  -m "mpower" -r

IPADDR=`ifconfig ath0 | grep 'inet addr' | cut -d ':' -f 2 | awk '{ print $1 }'`
$PUBBIN -h $mqtthost $auth -t $topic/\$localip -m "$IPADDR" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$fw/version -m "$version" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$fw/name -m "mPower MQTT" -r

#UPTIME=`awk '{print $1}' /proc/uptime`
#$PUBBIN -h $mqtthost $auth -t $topic/\$stats/uptime -m "$UPTIME" -r

properties=relay

if [ $energy -eq 1 ]
then
    properties=$properties,energy
fi

if [ $power -eq 1 ]
then
    properties=$properties,power
fi

if [ $voltage -eq 1 ]
then
    properties=$properties,voltage
fi

if [ $lock -eq 1 ]
then
    properties=$properties,lock
fi

if [ $current -eq 1 ]
then
    properties=$properties,current
fi

if [ $pfactor -eq 1 ]
then
    properties=$properties,pf
fi
# node infos
for i in $(seq $PORTS); do
	name=$(cat /var/etc/persistent/cfg/config_file | grep port.$((i-1)).label | sed 's/.*=\(.*\)/\1/')
	[ "$name" == "" ] && name="Port $i"
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$name -m "$name" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$type -m "power switch" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$properties -m "$properties" -r
	if [ $relay -eq 1 ]; then
		$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$settable -m "true" -r
	fi
	if [ $lock -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$settable -m "true" -r
	fi
done

$PUBBIN -h $mqtthost $auth -t $topic/\$state -m "ready" -r