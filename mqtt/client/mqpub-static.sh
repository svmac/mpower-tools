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
[ $energy -eq 1 ] && properties=$properties,energy
[ $power -eq 1 ] && properties=$properties,power
[ $voltage -eq 1 ] && properties=$properties,voltage
[ $lock -eq 1 ] && properties=$properties,lock
[ $current -eq 1 ] && properties=$properties,current
[ $pfactor -eq 1 ] && properties=$properties,pf

# node infos
for i in $(seq $PORTS); do
	name=$(cat /var/etc/persistent/cfg/config_file | grep port.$((i-1)).label | sed 's/.*=\(.*\)/\1/')
	[ "$name" == "" ] && name="Port $i"
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$name -m "$name" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$type -m "power switch" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$properties -m "$properties" -r
	$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$name -m "$name relay" -r
	$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$datatype -m "enum" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$format -m "ON,OFF" -r
	$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$settable -m "true" -r
	if [ $lock -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$name -m "$name lock" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$datatype -m "enum" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$format -m "ON,OFF" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$settable -m "true" -r
	fi
	if [ $energy -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy/\$name -m "$name energy" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy/\$datatype -m "integer" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy/\$unit -m "Wh" -r
	fi
	if [ $power -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/power/\$name -m "$name power" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/power/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/power/\$unit -m "W" -r
	fi
	if [ $voltage -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage/\$name -m "$name voltage" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage/\$unit -m "V" -r
	fi
	if [ $current -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/current/\$name -m "$name current" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/current/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/current/\$unit -m "A" -r
	fi
	if [ $pfactor -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf/\$name -m "$name pf" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf/\$unit -m "%" -r
	fi
done

$PUBBIN -h $mqtthost $auth -t $topic/\$state -m "ready" -r