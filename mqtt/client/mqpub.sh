#!/bin/sh

log() {
	logger -s -t "mqtt" "$*"
}

# read config file
source $BIN_PATH/client/mpower-pub.cfg

log "Found $((PORTS)) ports."
log "Publishing to $mqtthost with topic $topic"

REFRESHCOUNTER=$refresh
FASTUPDATE=0


export relay
export power
export energy
export voltage
export lock
export current
export pfactor

$BIN_PATH/client/mqpub-static.sh

loop_wait=2
for i in $(seq $PORTS);	do
if [ $power -eq 1 ]; then
	# current power
	$BIN_PATH/client/mqtask.sh $topic/port$i/power /proc/power/active_pwr$i $refresh $loop_wait 1 $percentvar &
fi
if [ $voltage -eq 1 ]; then
	# voltage
	$BIN_PATH/client/mqtask.sh $topic/port$i/voltage /proc/power/v_rms$i $refresh $loop_wait 1 $percentvar &
fi
if [ $current -eq 1 ]; then
	# current
	$BIN_PATH/client/mqtask.sh $topic/port$i/current /proc/power/i_rms$i $refresh $loop_wait 2 $percentvar &
fi
if [ $pfactor -eq 1 ]; then
	# power factor
	$BIN_PATH/client/mqtask.sh $topic/port$i/pf /proc/power/pf$i $refresh $loop_wait 2 $percentvar &
fi
done

sa=0
ra=""
la=""

while sleep $loop_wait; do
    if [ $relay -eq 1 ]; then
        # relay state
		rr=$(cat /proc/power/relay*)
		if [ "$rr" != "$ra" ]; then
			for i in $(seq $PORTS); do
				relay_val=$(cat /proc/power/relay$i)
				[ $relay_val -ne 1 ] &&	relay_val=0
				$PUBBIN -h $mqtthost $auth -t $topic/port$i/relay -m "$relay_val" -r
			done
			ra=$rr
		fi
    fi
    if [ $lock -eq 1 ]; then
        # lock
		ll=$(cat /proc/power/lock*)
		if [ "$ll" != "$la" ]; then
			for i in $(seq $PORTS); do
				port_val=$(cat /proc/power/lock$i)
				$PUBBIN -h $mqtthost $auth -t $topic/port$i/lock -m "$port_val" -r
			done
			la=$ll
		fi
    fi
    ss=$(date +%s)
	if [ $ss -gt $sa ]; then
		$PUBBIN -h $mqtthost $auth -t $topic/\$stats/uptime -m "$(awk '{print int($1/60)}' /proc/uptime)" -r
		$PUBBIN -h $mqtthost $auth -t $topic/uptime -m "$(uptime)" -r
        sa=$(( ss + refresh ))
		if [ $energy -eq 1 ]; then
			# energy consumption
			for i in $(seq $PORTS); do
				energy_val=$(cat /proc/power/energy_sum$i)
				energy_val=$(printf "%.0f" $energy_val)
				$PUBBIN -h $mqtthost $auth -t $topic/port$i/energy -m "$energy_val" -r
			done
		fi
    fi
done