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

#export GNS3_RELEASE_CHANNEL=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`
#FIXME: force to 2.2
export GNS3_RELEASE_CHANNEL="2.2"
echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

export GNS3_SRC="/tmp/GNS3VM.Hyper-V.${GNS3VM_VERSION}.ova"

if [[ "$GNS3_VM_FILE" == "" ]]
then
    export GNS3VM_VERSION="0.10.24" # `python last_vm_version.py`
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    if [[ ! -f "/tmp/GNS3VM.Hyper-V.${GNS3VM_VERSION}.zip" ]]
    then
        echo "Downloading $GNS3VM_URL"
        curl -Lk "$GNS3VM_URL" > "/tmp/GNS3VM.Hyper-V.${GNS3VM_VERSION}.zip"
    fi
else
    echo "GNS3 VM file: $GNS3_VM_FILE"
    export GNS3VM_VERSION=`cat version`
    cp "$GNS3_VM_FILE" "/tmp/GNS3VM.Hyper-V.${GNS3VM_VERSION}.zip"
fi
unzip -p "/tmp/GNS3VM.Hyper-V.${GNS3VM_VERSION}.zip" "GNS3 VM.ova" > ${GNS3_SRC}

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
zip -9 "../GNS3 VM Hyper-V ${GNS3_VERSION}.zip" *.vhd create-vm.ps1

cd ..
rm -Rf output-*
rm ${GNS3_SRC}
