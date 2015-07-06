#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

packer build -only=virtualbox-iso gns3.json
packer build -only=virtualbox-ovf gns3_compress.json
