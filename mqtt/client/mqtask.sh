#!/bin/sh

topic=$1
pfile=$2
refresh=$3
ww=$4
dd=$5
pp=$6

ia=0
sa=0

while sleep $ww; do
	ii=$(printf "%.${dd}f" $(cat $pfile))
    ss=$(date +%s)
    swi=0
    [ "$pp" != "" ] && swi=$(echo "$ia $ii $pp" | awk '{ a=$1; i=$2; p=a*$3/100 } ; END { print (((i > (a+p)) || (i < (a-p)))?1:0) }')
    [ $swi -eq 0 ] && [ $ss -gt $sa ] && swi=1
    #echo "$swi $ss $sa $ii $ia $pp"
    if [ $swi -eq 1 ]; then
        $PUBBIN -h $mqtthost $auth -t $topic -m "$ii" -r
        sa=$(( ss + refresh ))
		ia=$ii
    fi
done