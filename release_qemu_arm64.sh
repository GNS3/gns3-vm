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

if [[ "$GNS3_VM_FILE" == "" ]]
then
    export GNS3VM_VERSION="0.15.0" # `python last_vm_version.py`
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3VM.ARM64.${GNS3VM_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    curl --insecure -L "$GNS3VM_URL" > "/tmp/GNS3VM.ARM64.${GNS3VM_VERSION}.zip"
else
    echo "GNS3 VM file: $GNS3_VM_FILE"
    cp "$GNS3_VM_FILE" "/tmp/GNS3VM.ARM64.${GNS3VM_VERSION}.zip"
fi

unzip -o "/tmp/GNS3VM.ARM64.${GNS3VM_VERSION}.zip"

packer build -only=qemu-arm64 gns3_release.json

rm -Rf output-qemu-arm64

for qcow2_file in *.qcow2
do
    echo "Converting ${qcow2_file} to VMDK format..."
    vmdk_file=`basename "${qcow2_file}" .qcow2`
    qemu-img convert -O vmdk "${qcow2_file}" "${vmdk_file}.vmdk"
done

zip -9 "GNS3.VM.ARM64.${GNS3_VERSION}.zip" *.vmdk
