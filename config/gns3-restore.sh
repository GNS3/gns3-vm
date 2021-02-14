#!/bin/bash
#
# This command allows to fix a broken installation
#

if [[ $(id -u) -ne 0 ]] 
then
    echo "Please run this script as root or using sudo"
    exit 1
fi

export BRANCH="focal-unstable"
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/restore.sh" | bash
