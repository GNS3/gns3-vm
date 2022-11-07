#!/bin/bash

# Setup Ubuntu
# This script should be run as root

set -e

# Auto login
apt-get update

if [[ "$(dpkg --print-architecture)" == "arm64" ]]
then
  DATA_DISK="/dev/vdb"
  DATA_PART="/dev/vdb1"
else
  DATA_DISK="/dev/sdb"
  DATA_PART="/dev/sdb1"
fi

# Create the /opt disk
echo -e "o\nn\np\n1\n\n\nw" | fdisk $DATA_DISK
mkfs.ext4 $DATA_PART
echo "UUID=$(blkid -s UUID -o value $DATA_PART)  /opt  ext4  nodiratime  0  2" >> /etc/fstab
mount -a

echo "Ubuntu has been setup"
