#!/bin/bash
#
# This script build the VM without the GNS3 server installed
#
set -e

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

packer build -force -only=virtualbox-iso $* gns3.json

cd output-virtualbox-iso
7z a -bsp1 -mx=1 "../GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip" "GNS3 VM.ova"

rm -Rf output-*
