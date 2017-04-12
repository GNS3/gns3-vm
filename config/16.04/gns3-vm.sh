#!/bin/bash

command -v vmtoolsd >/dev/null 2>&1 || exit 0

IP=""
while [ "$IP" == "" ]
do
    IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1`
    sleep 1
done

vmtoolsd --cmd "info-set guestinfo.gns3.eth0 $IP"
exit 0

