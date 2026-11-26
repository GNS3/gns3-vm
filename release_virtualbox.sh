#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass GNS3 version as parameter
#

set -e

export GNS3_VERSION=`echo $1 | sed "s/^v//"`
export GNS3_OVA_FILE=$2

if [[ "$GNS3_VERSION" == "" ]]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

if [[ "$GNS3_OVA_FILE" == "" ]]
then
    echo "You need to pass the GNS3 VM OVA (VMware) file as parameter"
    exit 1
fi

start=$SECONDS

echo "Building VirtualBox VM for GNS3 $GNS3_VERSION"

# Build the VM based on the VMware OVA
export GNS3_SRC="$GNS3_OVA_FILE"
packer build -only=virtualbox-ovf gns3_release_virtualbox.json

cd output-virtualbox-ovf
mv "GNS3 VM.ova" "../GNS3.VM.VirtualBox.${GNS3_VERSION}.ova"

cd ..
rm -Rf output-virtualbox-ovf

echo "VirtualBox VM build completed in $((SECONDS - start)) seconds"
