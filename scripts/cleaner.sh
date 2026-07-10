#!/bin/bash

# Purge old kernels
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt -y purge
dpkg -l 'linux-headers-*' | grep '^ii'|sed 's/^ii[ ]*//'| cut -f1 -d' '| xargs sudo apt -y purge
dpkg -l 'linux-image-extra-*' | grep '^ii'|sed 's/^ii[ ]*//'| cut -f1 -d' '| xargs sudo apt -y purge

# Delete the massive firmware packages
sudo rm -rf /lib/firmware/*
sudo rm -rf /usr/share/doc/linux-firmware/*

# remove packages that are not needed in the GNS3 VM
sudo apt -y remove --purge snapd
sudo apt -y remove --purge python3-botocore
sudo apt -y remove --purge python3-twisted
#sudo apt -y remove --purge mesa-vulkan-drivers
#sudo apt -y remove --purge libwebkitgtk-6.0-4
#sudo apt -y remove --purge libjavascriptcoregtk-6.0-1

# Purge locale
sudo rm -Rf /usr/share/locale/*
sudo locale-gen --purge --lang en_US

sudo apt -y autoremove --purge
sudo apt -y autoclean
sudo apt -y clean

sudo rm -Rf /var/lib/apt/lists/*
sudo rm -Rf /var/cache/apt/*
sudo rm -Rf /var/cache/debconf/*
sudo rm -Rf /var/cache/man/*
sudo rm -Rf /var/log/installer/*
sudo rm -Rf /usr/share/doc
sudo rm -Rf /var/lib/docker/devicemapper
sudo rm -Rf /tmp/*

# Blank netplan machine-id (DUID) so machines get unique ID generated on boot.
sudo truncate -s 0 /etc/machine-id

# Clean journal logs
sudo journalctl --vacuum-time=1s

# Defragment
sudo e4defrag / &>/dev/null

# Setup zerofree for disk compaction
sudo bash /usr/local/bin/zerofree

if [[ $PACKER_BUILDER_TYPE == "vmware-iso" ]]
then
   sudo vmware-toolbox-cmd disk shrink /
fi
