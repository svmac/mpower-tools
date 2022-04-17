#!/bin/sh

# homie spec 4.0.0 (complete)
$PUBBIN -h $mqtthost $auth -t $topic/\$state -m "init" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$homie -m "4.0.0" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$name -m "$devicename" -r

LABELS=$(cat /var/etc/persistent/cfg/config_file | grep label)
if [ "$LABELS" == "" ]; then
	NODES=`seq $PORTS | sed 's/\([0-9]\)/port\1/' | tr '\n' , | sed 's/.$//'`
else
	NODES=$(echo "$LABELS" | sed 's/.*=\(.*\)/\1/' | tr '\n' , | sed 's/.$//')
fi
$PUBBIN -h $mqtthost $auth -t $topic/\$nodes -m "$NODES" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$extensions -m "" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$implementation  -m "mpower" -r

HWADDR=`ifconfig ath0 | grep 'HWaddr' | tr -d ':' | cut -d 'H' -f 2 | awk '{ print $2 }'`
IPADDR=`ifconfig ath0 | grep 'inet addr' | cut -d ':' -f 2 | awk '{ print $1 }'`

#HA
hatopic=homeassistant
hadev="\"device\":{\"ids\":\"$HWADDR\",\"name\":\"$devicename\",\"sw\":\"$version\",\"mdl\":\"mPower\",\"mf\":\"Ubiquiti\",\"cu\":\"http://$IPADDR\"}"
haavl="\"avty_t\":\"$topic/\$state\",\"pl_avail\":\"ready\",\"pl_not_avail\":\"lost\""
hanm=${devicename}_Status
$PUBBIN -h $mqtthost $auth -t "$hatopic/binary_sensor/$hanm/config" -m "{\"dev_cla\":\"connectivity\",\"pl_on\":\"ready\",\"pl_off\":\"lost\",\"name\":\"$hanm\",\"stat_t\":\"$topic/\$state\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r
hanm=${devicename}_Uptime
$PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"unit_of_meas\":\"m\",\"icon\":\"mdi:timer\",\"name\":\"$hanm\",\"stat_t\":\"$topic/\$stats/uptime\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r
hanm=${devicename}_UptimeX
$PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"icon\":\"mdi:new-box\",\"name\":\"$hanm\",\"stat_t\":\"$topic/uptime\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r
hanm=${devicename}_IP
$PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"icon\":\"hass:server-network\",\"name\":\"$hanm\",\"stat_t\":\"$topic/\$localip\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r
hanm=${devicename}_Ocupacion
$PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"unit_of_meas\":\"%\",\"icon\":\"mdi:circle-slice-3\",\"name\":\"$hanm\",\"stat_t\":\"$topic/ocupacion\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r



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
	name=$(echo "$LABELS" | grep $((i-1)).label | sed 's/.*=\(.*\)/\1/')
	[ "$name" == "" ] && name="Port $i"
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$name -m "$name" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$type -m "power switch" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$properties -m "$properties" -r
	$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$name -m "$name relay" -r
	$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$datatype -m "enum" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$format -m "ON,OFF" -r
	$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$settable -m "true" -r

    hanm=${devicename}_SW${i}_$name
    $PUBBIN -h $mqtthost $auth -t "$hatopic/switch/$hanm/config" -m "{\"icon\":\"mdi:power-socket-eu\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/relay\",\"cmd_t\":\"$topic/port$i/relay/set\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r

    hadevp="\"device\":{\"ids\":\"$HWADDR$i\",\"name\":\"$name\",\"sw\":\"$IPADDR\",\"mdl\":\"Port$i\",\"mf\":\"mPower\",\"cu\":\"http://$IPADDR\"}"
    hanm=${name}_Relay
    $PUBBIN -h $mqtthost $auth -t "$hatopic/switch/$hanm/config" -m "{\"icon\":\"mdi:power-socket-eu\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/relay\",\"cmd_t\":\"$topic/port$i/relay/set\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r


	if [ $lock -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$name -m "$name lock" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$datatype -m "enum" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$format -m "ON,OFF" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$settable -m "true" -r
        hanm=${name}_Lock
        $PUBBIN -h $mqtthost $auth -t "$hatopic/switch/$hanm/config" -m "{\"icon\":\"mdi:mdi-lock\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/lock\",\"cmd_t\":\"$topic/port$i/lock/set\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r
	fi
	if [ $energy -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy/\$name -m "$name energy" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy/\$datatype -m "integer" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy/\$unit -m "Wh" -r
        hanm=${name}_Energy
        $PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"dev_cla\":\"energy\",\"unit_of_meas\":\"Wh\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/energy\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r
	fi
	if [ $power -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/power/\$name -m "$name power" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/power/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/power/\$unit -m "W" -r
        hanm=${name}_Power
        $PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"dev_cla\":\"power\",\"unit_of_meas\":\"W\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/power\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r
	fi
	if [ $voltage -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage/\$name -m "$name voltage" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage/\$unit -m "V" -r
        hanm=${name}_Voltage
        $PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"dev_cla\":\"voltage\",\"unit_of_meas\":\"V\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/voltage\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r
	fi
	if [ $current -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/current/\$name -m "$name current" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/current/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/current/\$unit -m "A" -r
        hanm=${devicename}_I${i}_$name
        $PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"dev_cla\":\"current\",\"unit_of_meas\":\"A\",\"icon\":\"mdi:current-ac\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/current\",$haavl,\"uniq_id\":\"$hanm\",$hadev}" -r
        hanm=${name}_Current
        $PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"dev_cla\":\"current\",\"unit_of_meas\":\"A\",\"icon\":\"mdi:current-ac\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/current\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r
	fi
	if [ $pfactor -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf/\$name -m "$name pf" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf/\$datatype -m "float" -r
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf/\$unit -m "%" -r
        hanm=${name}_PowerFactor
        $PUBBIN -h $mqtthost $auth -t "$hatopic/sensor/$hanm/config" -m "{\"dev_cla\":\"power_factor\",\"unit_of_meas\":\"%\",\"name\":\"$hanm\",\"stat_t\":\"$topic/port$i/pf\",$haavl,\"uniq_id\":\"$hanm\",$hadevp}" -r
	fi
done

$PUBBIN -h $mqtthost $auth -t $topic/\$state -m "ready" -r
