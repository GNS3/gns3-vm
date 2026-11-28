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

start=$SECONDS

rm -Rf kvm-build
mkdir kvm-build
cd kvm-build

cp ../gns3vm-disk1.vmdk .
cp ../gns3vm-disk2.vmdk .

for vmdk_file in gns3vm-disk{1,2}.vmdk; do
    echo "Converting ${vmdk_file} to Qcow2 format..."
    qcow2_file=`basename "${vmdk_file}" .vmdk`
    qemu-img convert -O qcow2 "${vmdk_file}" "${qcow2_file}.qcow2"
done

cp ../start-gns3vm.sh .
cp ../gns3vm_libvirt.xml .

# Update disk paths in the libvirt XML with the current GNS3 version
sed -i "s|GNS3\.VM\.KVM\.[0-9.]\+|GNS3.VM.KVM.${GNS3_VERSION}|g" gns3vm_libvirt.xml

set -o pipefail
tar -Scf - gns3vm-disk{1,2}.qcow2 gns3vm_libvirt.xml start-gns3vm.sh | pv -f -b -t -r | xz --threads=0 > ../"GNS3.VM.KVM.${GNS3_VERSION}.tar.xz"

echo "KVM VM for GNS3 $GNS3_VERSION created in $((SECONDS - start)) seconds"
