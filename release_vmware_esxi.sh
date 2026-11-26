#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 version as parameter
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

echo "Building ESXi VM for GNS3 $GNS3_VERSION using $GNS3_OVA_FILE"

start=$SECONDS

echo "Upgrading OVA for VMware ESXi"
rm -Rf output-esxi
mkdir output-esxi
cp "$GNS3_OVA_FILE" output-esxi/GNS3-VM.ova
cd output-esxi
python3 ../workstation_to_esxi.py "GNS3-VM.ova" "GNS3.VM.VMware.ESXI.${GNS3_VERSION}.ova"
mv "GNS3.VM.VMware.ESXI.${GNS3_VERSION}.ova" ../
cd ..
rm -Rf output-esxi

echo "ESXi VM build completed in $((SECONDS - start)) seconds"
