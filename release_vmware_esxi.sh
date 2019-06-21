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

export GNS3_UPDATE_FLAVOR=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`

echo "Build VM for GNS3 $GNS3_VERSION"
echo "Update flavor: $GNS3_UPDATE_FLAVOR"

echo "Download VM"
export GNS3VM_URL="https://github.com/GNS3/gns3-gui/releases/download/v${GNS3_VERSION}/GNS3.VM.VMware.Workstation.${GNS3_VERSION}.zip"
if [[ ! -f "/tmp/GNS3VM.VMware.${GNS3_VERSION}.zip" ]]
then
    echo "Download $GNS3VM_URL"
    curl -Lk "$GNS3VM_URL" > "/tmp/GNS3VM.VMware.${GNS3_VERSION}.zip"
fi
unzip -p "/tmp/GNS3VM.VMware.${GNS3_VERSION}.zip" "GNS3 VM.ova" > "/tmp/GNS3VM.VMWare.${GNS3_VERSION}.ova"

echo "Upgrade OVA for ESXI"
rm -Rf output-esxi
mkdir output-esxi
cd output-esxi
python3 ../workstation_to_esxi.py "/tmp/GNS3VM.VMWare.${GNS3_VERSION}.ova" "GNS3 VM.ova"

zip -9 "../GNS3 VM VMware ESXI ${GNS3_VERSION}.zip" "GNS3 VM.ova"


cd ..
rm -Rf output-*
#rm  "/tmp/GNS3VM.VMware.${GNS3VM_VERSION}.zip"

