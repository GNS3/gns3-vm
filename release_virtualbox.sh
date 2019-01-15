#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass GNS3 version as parameter
#

set -e


export PATH=$PATH:/Applications/VMware\ OVF\ Tool/
export GNS3_VERSION=`echo $1 | sed "s/^v//"`

if [ "$GNS3_VERSION" == "" ]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

export GNS3_RELEASE_CHANNEL=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`

echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

rm -Rf output-*
export GNS3VM_VERSION=`python last_vm_version.py`
export GNS3_SRC="/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.ova"

if [ ! -f $GNS3_SRC ]
then
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3.VM.VirtualBox.${GNS3VM_VERSION}.zip"
    echo "Download $GNS3VM_URL"
    curl --insecure -L "$GNS3VM_URL" > "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip"
    unzip -p "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip" "GNS3 VM.ova" > $GNS3_SRC
    rm  "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip"    
fi

packer build -only=virtualbox-ovf gns3_release.json

cd output-virtualbox-ovf

zip -9 "../GNS3 VM VirtualBox ${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-*
rm $GNS3_SRC

