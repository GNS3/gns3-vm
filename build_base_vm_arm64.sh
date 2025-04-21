#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`

echo "Build Base VM $GNS3VM_VERSION for ARM64"

rm -Rf output-qemu-amd64
if [[ ! -f "./noble-server-cloudimg-arm64.img" ]]
then
  # download the cloud image outside packer
   curl -O https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-arm64.img
fi
packer build -only=qemu-arm64 $* base_vm.json

cd output-qemu-arm64
qemu-img convert -O qcow2 "GNS3 VM" gns3vm-disk1.qcow2
rm "GNS3 VM"
qemu-img convert -O qcow2 "GNS3 VM-1" gns3vm-disk2.qcow2
rm "GNS3 VM-1"

7zz a -bsp1 -mx=1 "../GNS3VM.Base.ARM64.${GNS3VM_VERSION}.zip" gns3vm-disk1.qcow2 gns3vm-disk2.qcow2

cd ..
rm -Rf output-qemu-arm64
