#!/bin/sh

command -v vmtoolsd >/dev/null 2>&1 || exit 0

IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | cut -d' ' -f1`

vmtoolsd --cmd "info-set guestinfo.gns3.eth0 $IP"


