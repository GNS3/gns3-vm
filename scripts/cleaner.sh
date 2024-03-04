#!/bin/bash

# Purge old kernels
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
dpkg -l 'linux-headers-*' | grep '^ii'|sed 's/^ii[ ]*//'| cut -f1 -d' '| xargs sudo apt-get -y purge
dpkg -l 'linux-image-extra-*' | grep '^ii'|sed 's/^ii[ ]*//'| cut -f1 -d' '| xargs sudo apt-get -y purge

# Delete the massive firmware packages
sudo rm -rf /lib/firmware/*
sudo rm -rf /usr/share/doc/linux-firmware/*

# Purge locale
sudo rm -Rf /usr/share/locale/*
sudo locale-gen --purge --lang en_US

sudo apt-get -y autoremove --purge
sudo apt-get -y autoclean
sudo apt-get -y clean

# Clean up orphaned packages with deborphan
#sudo apt-get -y install deborphan
#while [[ -n "$(deborphan --guess-all --libdevel)" ]]; do
#    deborphan --guess-all --libdevel | xargs sudo apt-get -y purge
#done
#sudo apt-get -y purge deborphan

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

# Defragment
sudo e4defrag / &>/dev/null

# Setup zerofree for disk compaction
sudo bash /usr/local/bin/zerofree
