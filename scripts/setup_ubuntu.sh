#!/bin/bash

# Setup Ubuntu
# This script should be run as root

# Auto login
apt-get update

# Create the /opt disk
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
mkfs.ext4 /dev/sdb1
echo "UUID=$(blkid -s UUID -o value /dev/sdb1)  /opt  ext4  nodiratime  0  2" >> /etc/fstab
mount -a

echo "Ubuntu has been setup"
