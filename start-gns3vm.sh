#!/bin/bash

if [[ ! $(ip link show virbr0) ]]
then
  sudo apt update
  sudo apt install -y libvirt-bin
fi

if [[ ! $(ip link show tap-gns3vm) ]]
then
  echo "Creating TAP interface"
  sudo ip tuntap add dev tap-gns3vm mode tap user $(whoami)
  sudo ip link set tap-gns3vm up
  sudo brctl addif virbr0 tap-gns3vm
fi

qemu-system-x86_64 -name "GNS3 VM" -m 2048M -cpu host -enable-kvm -machine smm=off -boot order=c \
-drive file="GNS3 VM-disk001.qcow2",if=virtio,index=0,media=disk \
-drive file="GNS3 VM-disk002.qcow2",if=virtio,index=1,media=disk \
-device virtio-net-pci,netdev=nic0 -netdev tap,id=nic0,ifname=tap-gns3vm,script=no,downscript=no

#qemu-system-x86_64 -name "GNS3 VM" -nographic -m 2048 -smp 2 -machine accel=kvm \
#-netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 -device virtio-net-pci,netdev=vnet \
#-drive file=gns3vm-disk1.qcow2,if=virtio,cache=none,format=qcow2 \
#-drive file=gns3vm-disk2.qcow2,if=virtio,cache=none,format=qcow2 \
#-cdrom seed.iso
