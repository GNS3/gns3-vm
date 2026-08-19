#!/bin/bash

qemu-system-aarch64 -name "GNS3 VM" -nographic -m 2048 -machine virt -cpu max -smp 4 \
-netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 -device virtio-net-pci,netdev=vnet \
-drive file=gns3vm-disk1.qcow2,if=virtio,cache=none,format=qcow2 \
-drive file=gns3vm-disk2.qcow2,if=virtio,cache=none,format=qcow2 \
-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
