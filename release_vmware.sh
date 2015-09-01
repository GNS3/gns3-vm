#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 version as parameter
#

set -e




export PATH=$PATH:/Applications/VMware\ OVF\ Tool/
export GNS3_VERSION=`echo $1 | sed "s/^v//"`

if [ "$GNS3_VERSION" == "" ]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi



echo "Build VM for GNS3 $GNS3_VERSION"

export GNS3VM_VERSION=`python last_vm_version.py`
export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3.VM.VMware.${GNS3VM_VERSION}.zip"
echo "Download $GNS3VM_URL"
curl --insecure -L "$GNS3VM_URL" > "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip"
unzip -p "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip" "GNS3 VM.ova" > "/tmp/GNS3VM.VMWare.${GNS3VM_VERSION}.ova"
rm  "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip"

rm -Rf output-vmx
mkdir output-vmx
ovftool --allowAllExtraConfig "/tmp/GNS3VM.VMWare.${GNS3VM_VERSION}.ova" output-vmx/gns3.vmx

rm "/tmp/GNS3VM.VMWare.${GNS3VM_VERSION}.ova"
rm -Rf output-vmware-vmx
export GNS3_SRC="output-vmx/gns3.vmx"
packer build -only=vmware-vmx gns3_release.json

cd output-vmware-vmx

ovftool --allowAllExtraConfig "GNS3 VM.vmx" "GNS3 VM.ova"

zip -9 "../GNS3 VM VMware Workstation ${GNS3_VERSION}.zip" "GNS3 VM.ova"

mv "GNS3 VM.ova" "GNS3 VM Workstation.ova"

python ../workstation_to_esxi.py "GNS3 VM Workstation.ova" "GNS3 VM.ova"

zip -9 "../GNS3 VM VMware ESXI ${GNS3_VERSION}.zip" "GNS3 VM.ova"


cd ..
rm -Rf output-*

