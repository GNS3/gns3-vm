#!/bin/bash

set -e


export PATH=$PATH:/Applications/VMware\ OVF\ Tool/

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

rm -Rf output-vmware-iso
packer build -only=vmware-iso gns3.json

ovftool --extraConfig:vhv.enable=true --extraConfig:ethernet0.connectionType=hostonly --extraConfig:ethernet1.present=true --allowAllExtraConfig --overwrite output-vmware-iso/GNS3\ VM.vmx GNS3\ VM\ VMware\ ${GNS3VM_VERSION}.ova
