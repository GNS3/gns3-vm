#!/bin/bash

set -e


if [ "$GNS3_VERSION" == "" ]
then
    echo "You need to export the GNS3_VERSION variable if you want to build the VM. Example export GNS3_VERSION=1.4.0"
    exit 1
fi

export PATH=$PATH:/Applications/VMware\ OVF\ Tool/

export GNS3_VERSION=`echo $GNS3_VERSION | sed "s/^v//"` 
export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

rm -Rf output-vmware-iso
packer build -only=vmware-iso gns3.json

rm -Rf output-vmware-ova
mkdir output-vmware-ova

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
        --overwrite output-vmware-iso/GNS3\ VM.vmx output-vmware-ova/GNS3\ VM.ova

cd output-vmware-ova
zip -9 "../GNS3 VM VMware ${GNS3VM_VERSION}.zip" "GNS3 VM.ova"
