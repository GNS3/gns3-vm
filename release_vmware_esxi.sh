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

#export GNS3_RELEASE_CHANNEL=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`
#FIXME: force to 2.2
export GNS3_RELEASE_CHANNEL="2.2"

echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

if [[ ! -f "/tmp/GNS3VM.VMware.${GNS3_VERSION}.zip" ]]
then
    export GNS3VM_URL="https://github.com/GNS3/gns3-gui/releases/download/v${GNS3_VERSION}/GNS3.VM.VMware.Workstation.${GNS3_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    curl -Lk --http1.1 "$GNS3VM_URL" > "/tmp/GNS3VM.VMware.${GNS3_VERSION}.zip"
fi

7z e -y "/tmp/GNS3VM.VMware.${GNS3_VERSION}.zip" "GNS3 VM.ova"
mv "GNS3 VM.ova" "/tmp/GNS3VM.VMWare.${GNS3_VERSION}.ova"

echo "Upgrading OVA for VMware ESXi"
rm -Rf output-esxi
mkdir output-esxi
cd output-esxi
python3 ../workstation_to_esxi.py "/tmp/GNS3VM.VMWare.${GNS3_VERSION}.ova" "GNS3 VM.ova"
7z a -bsp1 -mx=1 "../GNS3.VM.VMware.ESXI.${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-*
