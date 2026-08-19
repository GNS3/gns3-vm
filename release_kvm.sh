#!/bin/bash
#
# This script take a VM and install GNS3 server on it
#
# You need to pass GNS3 version as parameter
#

set -e

export GNS3_VERSION=`echo $1 | sed "s/^v//"`

if [[ "$GNS3_VERSION" == "" ]]
then
    echo "You need to pass the GNS3 version as parameter"
    exit 1
fi

echo "Creating KVM VM for GNS3 $GNS3_VERSION"
echo "Release channel: $GNS3_RELEASE_CHANNEL"

if [[ ! -f "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.zip" ]]
then
    echo "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.zip does not exist"
    exit 1
fi

7z e -y "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.zip" "GNS3 VM.ova"
mv "GNS3 VM.ova" "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.ova"

rm -Rf kvm-build
mkdir kvm-build
cd kvm-build

tar -xvf "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.ova"
for vmdk_file in GNS3\ VM*.vmdk; do
    echo "Converting ${vmdk_file} to Qcow2 format..."
    qcow2_file=`basename "${vmdk_file}" .vmdk`
    qemu-img convert -O qcow2 "${vmdk_file}" "${qcow2_file}.qcow2"
done

cp ../gns3vm_libvirt.xml .

# Update disk paths in the libvirt XML with the current GNS3 version
sed -i "s|GNS3\.VM\.KVM\.[0-9.]\+|GNS3.VM.KVM.${GNS3_VERSION}|g" gns3vm_libvirt.xml

7z a -bsp1 -mx=1 "../GNS3.VM.KVM.${GNS3_VERSION}.zip" *.qcow2 gns3vm_libvirt.xml ../start-gns3vm.sh

rm "/tmp/GNS3VM.VirtualBox.${GNS3_VERSION}.ova"
