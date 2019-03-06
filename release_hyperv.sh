#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 version as parameter
#

set -e

export GNS3_VERSION=`echo $1 | sed "s/^v//"`

if [[ "$GNS3_VERSION" == "" ]]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

export GNS3_RELEASE_CHANNEL=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`

echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

if [[ ! -f "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.zip" ]]
then
    export GNS3VM_URL="https://github.com/GNS3/gns3-gui/releases/download/v${GNS3_VERSION}/GNS3.VM.VirtualBox.${GNS3_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    curl --insecure -L "$GNS3VM_URL" > "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.zip"
fi

unzip -p "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.zip" "GNS3 VM.ova" > "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.ova"

rm -Rf output-hyperv
mkdir output-hyperv
cd output-hyperv

tar -xvf "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.ova"
for vmdk_file in *.vmdk; do
    echo "Converting ${vmdk_file} to VHD format..."
    vhd_file=`basename "${vmdk_file}" .vmdk`
    vboxmanage clonemedium --format vhd "${vmdk_file}" "${vhd_file}.vhd"
done

zip -9 "../GNS3 VM Hyper-V ${GNS3_VERSION}.zip" *.vhd
cd ..
rm -Rf output-*
