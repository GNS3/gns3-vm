#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass GNS3 version as parameter
#

set -e

export GNS3_VERSION=`echo $1 | sed "s/^v//"`
export GNS3_VM_FILE=$2

if [[ "$GNS3_VERSION" == "" ]]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

if [[ "$GNS3_VM_FILE" == "" ]]
then
    echo "You need to pass the GNS3 VM file as parameter"
    exit 1
fi


export GNS3_RELEASE_CHANNEL="3.0"
echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

# Build the VM based on the VirtualBox OVA
7z e -y $GNS3_VM_FILE
export GNS3_SRC="GNS3 VM.ova"

# Install the virtual kernel & tools, this is to support LIS (Linux Integration Services)
# for Hyper-V to find the guest IP address.
packer build -only=virtualbox-ovf gns3_release_hyperv.json

cd output-virtualbox-ovf

tar -xvf "GNS3 VM.ova"
for vmdk_file in *.vmdk; do
    echo "Converting ${vmdk_file} to VHD format..."
    vhd_file=`basename "${vmdk_file}" .vmdk`
    vboxmanage clonemedium --format vhd "${vmdk_file}" "${vhd_file}.vhd"
done

cp ../create-vm.ps1 create-vm.ps1
cp ../install-vm.bat install-vm.bat
7z a -bsp1 -mx=1 "../GNS3.VM.Hyper-V.${GNS3_VERSION}.zip" *.vhd create-vm.ps1 install-vm.bat

cd ..
rm -Rf output-virtualbox-ovf

