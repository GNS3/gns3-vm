#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`
export GNS3_RELEASE_CHANNEL=`cat release_channel`

echo "Build Base VM $GNS3VM_VERSION for AMD64"

rm -Rf output-qemu-amd64
if [[ ! -f "./resolute-server-cloudimg-amd64.img" ]]
then
  # download the cloud image outside packer
   curl -O https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img
fi

start=$SECONDS

packer build -only=qemu-amd64 -var "cpus=$(nproc)" $* base_vm.json

cd output-qemu-amd64
mv "GNS3 VM" ../gns3vm-base-disk1.qcow2
mv "GNS3 VM-1" ../gns3vm-base-disk2.qcow2

#7z a -bsp1 -mx=1 "../GNS3VM.Base.${GNS3VM_VERSION}.zip" gns3vm-disk1.qcow2 gns3vm-disk2.qcow2

echo "Base VM build completed in $((SECONDS - start)) seconds"
