#!/bin/bash
#
# This command allow to rescue a broken installation of the
# GNS3 VM
#

if [[ $(id -u) -ne 0 ]] 
then
    echo "Please run as root or with sudo"
    exit 1
fi
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/master/scripts/restore.sh" | bash
