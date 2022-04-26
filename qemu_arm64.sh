#!/bin/bash

set -e

export GNS3VM_VERSION=`cat version`

if [ ! -f "ubuntu-20.04.4-live-server-arm64.iso" ]
then
  wget https://cdimage.ubuntu.com/releases/20.04/release/ubuntu-20.04.4-live-server-arm64.iso
fi

mkdir -p ubuntu-arm64-iso
mount -r ubuntu-20.04.4-live-server-arm64.iso ubuntu-arm64-iso

qemu-img create -f qcow2 gns3vm-disk1.qcow2 20G
qemu-img create -f qcow2 gns3vm-disk2.qcow2 500G

nohup python3 -m http.server --directory http 4242 &

echo "Build VM $GNS3VM_VERSION for ARM64"

qemu-system-aarch64 -name "GNS3 VM" -nographic -m 4096 -cpu max -smp 8 \
-machine virt,gic-version=3,accel=kvm \
-netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 -device virtio-net-pci,netdev=vnet \
-drive file=gns3vm-disk1.qcow2,if=virtio,cache=none,format=qcow2 \
-drive file=gns3vm-disk2.qcow2,if=virtio,cache=none,format=qcow2 \
-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
-kernel ubuntu-arm64-iso/casper/vmlinuz -initrd ubuntu-arm64-iso/casper/initrd \
-append "autoinstall ds=nocloud-net;s=http://10.0.2.2:4242/ console=ttyAMA0" \
-cdrom ubuntu-20.04.4-live-server-arm64.iso -no-reboot -boot strict=off

packer build -only=qemu-arm64 $* gns3.json

rm -Rf output-qemu-arm64

cp gns3vm-disk1.qcow2 gns3vm-disk1.qcow2.bak
qemu-img convert -O qcow2 gns3vm-disk1.qcow2.bak gns3vm-disk1.qcow2

zip -9 "GNS3VM.ARM64.${GNS3VM_VERSION}.zip" gns3vm-disk1.qcow2 gns3vm-disk2.qcow2
