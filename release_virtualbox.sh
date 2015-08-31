#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 VM OVA as parameter and GNS3 version as second parameter
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

rm -Rf output-*
export GNS3_SRC=$1
packer build -only=virtualbox-ovf gns3_release.json

cd output-vmware-vmx

zip -9 "../GNS3 VM VirtualBox ${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-*

