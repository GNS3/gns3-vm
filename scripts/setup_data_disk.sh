#!/bin/bash

set -e

if [[ -b "/dev/vdb" ]]
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

echo "Data disk has been setup and partition mounted on /opt"
