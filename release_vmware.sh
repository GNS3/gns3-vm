#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 version as parameter
#

set -e

export PATH=$PATH:/Applications/VMware\ OVF\ Tool/
export GNS3_VERSION=`echo $1 | sed "s/^v//"`
export GNS3_VM_FILE=$2


if [ "$GNS3_VERSION" == "" ]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

export GNS3_UPDATE_FLAVOR=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`

echo "Build VM for GNS3 $GNS3_VERSION"
echo "Update flavor: $GNS3_UPDATE_FLAVOR"

if [ "$GNS3_VM_FILE" == "" ]
then
    echo "Download VM"
    export GNS3VM_VERSION=`python last_vm_version.py`
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3.VM.VMware.${GNS3VM_VERSION}.zip"
    if [ ! -f "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip" ]
    then
        echo "Download $GNS3VM_URL"
        curl --insecure -L "$GNS3VM_URL" > "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip"
    fi
else
    export GNS3VM_VERSION="dev"
    cp "$GNS3_VM_FILE" "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip"
fi
unzip -p "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip" "GNS3 VM.ova" > "/tmp/GNS3VM.VMWare.${GNS3VM_VERSION}.ova"


echo "Convert to VMX file format"
rm -Rf output-vmx
mkdir output-vmx
ovftool --allowAllExtraConfig "/tmp/GNS3VM.VMWare.${GNS3VM_VERSION}.ova" output-vmx/gns3.vmx

echo "Upgrade with packer"
rm "/tmp/GNS3VM.VMWare.${GNS3VM_VERSION}.ova"
rm -Rf output-vmware-vmx
export GNS3_SRC="output-vmx/gns3.vmx"
packer build -only=vmware-vmx gns3_release.json

cd output-vmware-vmx

echo "Export to OVA"
ovftool --extraConfig:vhv.enable=true                       \
        --extraConfig:ethernet0.virtualDev=e1000            \
        --extraConfig:ethernet0.pciSlotNumber=32            \
        --extraConfig:ethernet0.connectionType=hostonly     \
        --extraConfig:ethernet1.present=true                \
        --extraConfig:ethernet1.startConnected=true         \
        --extraConfig:ethernet1.connectionType=nat          \
        --extraConfig:ethernet1.addressType=generated       \
        --extraConfig:ethernet1.generatedAddressOffset=10   \
        --extraConfig:ethernet1.wakeOnPcktRcv=false         \
        --extraConfig:ethernet1.pciSlotNumber=33            \
        --extraConfig:ethernet1.virtualDev=e1000            \
        --allowAllExtraConfig                               \
        "GNS3 VM.vmx" "GNS3 VM.ova"


echo "Fix OVA network"
mv "GNS3 VM.ova" "GNS3 VM.tmp.ova"
python3 ../fix_vmware_ova_network.py "GNS3 VM.tmp.ova" "GNS3 VM.ova"
zip -9 "../GNS3 VM VMware Workstation ${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-*
#rm  "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip"

