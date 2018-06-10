#!/bin/bash

#
# This script will sync local config to an already
# installed VM.
#
# It's use in dev to test modifications
#

set -e

if [ "$1" == "" ]
then
    echo "Usage: push_config_to_vm.sh VM_IP"
    exit 1
fi

IP="$1"

rsync -av config/18.04 gns3@$IP:/tmp/config/
scp scripts/welcome.py gns3@$IP:/usr/local/bin/gns3welcome.py

ssh gns3@$IP "cd /tmp/config && sudo bash install.sh"
