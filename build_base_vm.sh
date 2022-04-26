#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`

echo "Build Base VM $GNS3VM_VERSION for AMD64"

rm -Rf output-qemu-amd64
packer build -only=qemu-amd64 $* base_vm.json

cd output-qemu-amd64
qemu-img convert -O qcow2 gns3vm-disk gns3vm-disk1.qcow2
rm gns3vm-disk
qemu-img convert -O qcow2 gns3vm-disk-1 gns3vm-disk2.qcow2
rm gns3vm-disk-1

zip -9 "../GNS3VM.Base.${GNS3VM_VERSION}.zip" gns3vm-disk1.qcow2 gns3vm-disk2.qcow2
