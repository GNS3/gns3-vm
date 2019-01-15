#!/bin/bash

# Add the IP address of the first adapter to the VM guest info
command -v vmtoolsd >/dev/null 2>&1 || exit 0

IP=""
while [ "$IP" == "" ]
do
    IP=`ip addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1`
    sleep 1
done

vmtoolsd --cmd "info-set guestinfo.gns3.eth0 $IP"
exit 0
