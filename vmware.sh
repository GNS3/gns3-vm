#!/bin/bash

set -e


export PATH=$PATH:/Applications/VMware\ OVF\ Tool/

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

rm -Rf output-vmware-iso
rm -Rf output-vmware-vmx
packer build -only=vmware-iso gns3.json
packer build -only=vmware-vmx gns3_compress.json

ovftool --extraConfig:vhv.enable=true --allowAllExtraConfig --overwrite output-vmware-vmx/GNS3\ VM.vmx GNS3\ VM\ ${GNS3VM_VERSION}.ova
