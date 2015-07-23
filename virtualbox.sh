#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

packer build -force -only=virtualbox-iso gns3.json

cd output-virtualbox-iso
zip -9 "../GNS3 VM VirtualBox ${GNS3VM_VERSION}.zip" "GNS3 VM.ova"
