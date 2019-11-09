#!/bin/sh

LOCALDIR="/var/etc/persistent/mqtt"
LOCALSCRIPTDIR=$LOCALDIR/client
BASEURL="https://raw.githubusercontent.com/svmac/mpower-tools/V4.0.0/mqtt"

update_script ()
{
    rm -f $LOCALSCRIPTDIR/$1
    wget --no-check-certificate -q $BASEURL/client/$1 -O $LOCALSCRIPTDIR/$1
    chmod 755 $LOCALSCRIPTDIR/$1
}

sleep 10
$LOCALSCRIPTDIR/mqstop.sh

update_script mqrun.sh
update_script mqpub-static.sh
update_script mqpub.sh
update_script mqsub.sh
update_script mqtask.sh

if [ ! -f $LOCALSCRIPTDIR/mpower-pub.cfg ]; then
    wget --no-check-certificate -q $BASEURL/client/mpower-pub.cfg -O $LOCALSCRIPTDIR/mpower-pub.cfg
fi

if [ ! -f $LOCALSCRIPTDIR/mqtt.cfg ]; then
    wget --no-check-certificate -q $BASEURL/client/mqtt.cfg -O $LOCALSCRIPTDIR/mqtt.cfg
fi

if [ ! -f $LOCALSCRIPTDIR/led.cfg ]; then
    wget --no-check-certificate -q $BASEURL/client/led.cfg -O $LOCALSCRIPTDIR/led.cfg
fi

[ -f $LOCALSCRIPTDIR/mqstop.sh ] && rm -f $LOCALSCRIPTDIR/mqstop.sh
ln -s $LOCALSCRIPTDIR/mqrun.sh $LOCALSCRIPTDIR/mqstop.sh

$LOCALSCRIPTDIR/mqrun.sh