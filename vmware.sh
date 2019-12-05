#!/bin/bash
#
# This script build the VM without the GNS3 server installed
#

set -e

export PATH=$PATH:/Applications/VMware\ OVF\ Tool/

export GNS3VM_VERSION=`cat version`

echo "Build VM $GNS3VM_VERSION"

rm -Rf output-vmware-iso
packer build -only=vmware-iso gns3.json

# workaround to clean the VMware VM due to problems
# after rebooting in order to install a new kernel
export GNS3_SRC="output-vmware-iso/GNS3 VM.vmx"
packer build -only=vmware-vmx gns3_clean.json

rm -Rf output-vmware-ova
mkdir output-vmware-ova

# Packer bug on post_vmx in 0.8.x we apply a second time the settings to the OVA
# Also we force export to remove the CD ROM
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
        --noImageFiles                                      \
        --overwrite output-vmware-vmx/GNS3\ VM.vmx output-vmware-ova/GNS3\ VM.ova

cd output-vmware-ova

echo "Fix OVA network"
python3 ../fix_vmware_ova_network.py "GNS3 VM.ova" "GNS3 VM FIX.ova"
mv "GNS3 VM FIX.ova" "GNS3 VM.ova"
zip -9 "../GNS3VM.VMware.${GNS3VM_VERSION}.zip" "GNS3 VM.ova"

rm -Rf output-*

