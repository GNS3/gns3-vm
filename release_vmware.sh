#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 VM OVA as parameter
#

set -e




export PATH=$PATH:/Applications/VMware\ OVF\ Tool/
export GNS3_VERSION=`echo $2 | sed "s/^v//"`

if [ "$GNS3_VERSION" == "" ]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi



echo "Build VM for GNS3 $GNS3_VERSION"

rm -Rf output-vmx
mkdir output-vmx
ovftool --allowAllExtraConfig "$1" output-vmx/gns3.vmx

rm -Rf output-vmware-vmx
export GNS3_SRC="output-vmx/gns3.vmx"
packer build -only=vmware-vmx gns3_release.json

cd output-vmware-vmx

ovftool --allowAllExtraConfig "GNS3 VM.vmx" "GNS3 VM.ova"

zip -9 "../GNS3 VM VMware ${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-*

