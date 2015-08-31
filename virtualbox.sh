#!/bin/bash

set -e

if [ "$GNS3_VERSION" == "" ]
then
    echo "You need to export the GNS3_VERSION variable if you want to build the VM. Example export GNS3_VERSION=1.4.0"
    exit 1
fi
export GNS3_VERSION=`echo $GNS3_VERSION | sed "s/^v//"` 

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

packer build -force -only=virtualbox-iso $* gns3.json

cd output-virtualbox-iso
zip -9 "../GNS3 VM VirtualBox ${GNS3VM_VERSION}.zip" "GNS3 VM.ova"
