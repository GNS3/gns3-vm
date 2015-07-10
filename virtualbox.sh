#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

packer build -force -only=virtualbox-iso gns3.json
mv output-virtualbox-iso/GSN3\ VM.ova GNS3\ VM\ VirtualBox\ ${GNS3VM_VERSION}.ova
