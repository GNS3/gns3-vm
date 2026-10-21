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
#FIXME: force to 3.1
export GNS3_RELEASE_CHANNEL="3.1"

echo "Build VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

if [[ "$GNS3_VM_FILE" == "" ]]
then
    export GNS3VM_VERSION="0.24.0" # `python last_vm_version.py`
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3VM.Base.ARM64.${GNS3VM_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    curl --insecure -L "$GNS3VM_URL" > "/tmp/GNS3VM.Base.ARM64.${GNS3VM_VERSION}.zip"
else
    echo "GNS3 VM file: $GNS3_VM_FILE"
    cp "$GNS3_VM_FILE" "/tmp/GNS3VM.Base.ARM64.${GNS3VM_VERSION}.zip"
fi

7z e -y "/tmp/GNS3VM.Base.ARM64.${GNS3VM_VERSION}.zip"

rm -Rf output-qemu-arm64
packer build -only=qemu-arm64 gns3_release.json

# Apple Virtualization requires RAW format, so we need to convert the QCOW2 files to RAW format
for qcow2_file in *.qcow2
do
    echo "Converting ${qcow2_file} to RAW format..."
    raw_file=`basename "${qcow2_file}" .qcow2`
    qemu-img convert -O raw "${qcow2_file}" "${raw_file}.img"
done

cp gns3vm*.img "GNS3 VM.utm/Data"
echo "Compressing RAW files to GNS3.VM.UTM.ARM64.${GNS3_VERSION}.tar.gz..."
tar -Sczf "GNS3.VM.UTM.ARM64.${GNS3_VERSION}.tar.gz" "GNS3 VM.utm"

exit 0
