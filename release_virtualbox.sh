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
#FIXME: force to 2.2dev
export GNS3_RELEASE_CHANNEL="2.2dev"
echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

export GNS3_SRC="/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.ova"

if [[ "$GNS3_VM_FILE" == "" ]]
then
    export GNS3VM_VERSION="0.10.18" # `python last_vm_version.py`
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    if [[ ! -f "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip" ]]
    then
        echo "Downloading $GNS3VM_URL"
        curl -Lk "$GNS3VM_URL" > "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip"
    fi
else
    echo "GNS3 VM file: $GNS3_VM_FILE"
    export GNS3VM_VERSION=`cat version`
    cp "$GNS3_VM_FILE" "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip"
fi
unzip -p "/tmp/GNS3VM.VirtualBox.${GNS3VM_VERSION}.zip" "GNS3 VM.ova" > ${GNS3_SRC}

packer build -only=virtualbox-ovf gns3_release.json

cd output-virtualbox-ovf

zip -9 "../GNS3 VM VirtualBox ${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-*
rm ${GNS3_SRC}
