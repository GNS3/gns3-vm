#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass the GNS3 version as parameter
#

set -e

export PATH=$PATH:/Applications/VMware\ OVF\ Tool/
export GNS3_VERSION=`echo $1 | sed "s/^v//"`
export GNS3_VM_FILE=$2

if [[ "$GNS3_VERSION" == "" ]]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

export GNS3_RELEASE_CHANNEL=`echo -n $GNS3_VERSION | sed "s/\.[^.]*$//"`

echo "Building VMware VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

if [[ "$GNS3_VM_FILE" == "" ]]
then
    export GNS3VM_URL="https://github.com/GNS3/gns3-vm/releases/download/v${GNS3VM_VERSION}/GNS3VM.Base.${GNS3VM_VERSION}.zip"
    echo "Download the base GNS3 VM version ${GNS3VM_VERSION} from GitHub"
    if [[ ! -f "/tmp/GNS3VM.Base.${GNS3VM_VERSION}.zip" ]]
    then
        echo "Downloading $GNS3VM_URL"
        curl -Lk "$GNS3VM_URL" > "/tmp/GNS3VM.Base.${GNS3VM_VERSION}.zip"
    fi
else
    echo "GNS3 VM file: $GNS3_VM_FILE"
    cp "$GNS3_VM_FILE" "/tmp/GNS3VM.Base.${GNS3VM_VERSION}.zip"
fi


unzip "/tmp/GNS3VM.Base.${GNS3VM_VERSION}.zip"

for qcow2_file in *.qcow2; do
    echo "Converting ${qcow2_file} to VMDK format..."
    vmdk_file=`basename "${qcow2_file}" .qcow2`
    qemu-img convert -O vmdk "${qcow2_file}" "${vmdk_file}.vmdk"
done

packer build -only=vmware-iso gns3_release.json

cd output-vmware-iso

echo "Export to OVA"
ovftool --noImageFiles --noNvramFile "GNS3 VM.vmx" "GNS3 VM.ova"
zip -9 "../GNS3.VM.VMware.Workstation.${GNS3_VERSION}.zip" "GNS3 VM.ova"

cd ..
rm -Rf output-vmware-iso
