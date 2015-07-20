#!/bin/bash

set -e


export PATH=$PATH:/Applications/VMware\ OVF\ Tool/

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

rm -Rf output-vmware-iso
packer build -only=vmware-iso gns3.json

#Packer bug on post_vmx in 0.8.x we apply a second time the settings to the OVA
ovftool \
        --extraConfig:vhv.enable=true                       \
        --extraConfig:ethernet0.connectionType=hostonly     \
        --extraConfig:ethernet1.present=true                \
        --extraConfig:ethernet1.startConnected=true         \
        --extraConfig:ethernet1.connectionType=nat          \
        --extraConfig:ethernet1.addressType=generated       \
        --extraConfig:ethernet1.generatedAddressOffset=10   \
        --extraConfig:ethernet1.wakeOnPcktRcv=false         \
        --extraConfig:ethernet1.pciSlotNumber=33            \
        --allowAllExtraConfig                               \
        --overwrite output-vmware-iso/GNS3\ VM.vmx GNS3\ VM\ VMware\ ${GNS3VM_VERSION}.ova
