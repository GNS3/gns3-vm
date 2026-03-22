#!/bin/bash

sudo apt-get purge -y --yes vim-common
sudo apt-get purge -y --yes usbutils
sudo apt-get purge -y --yes man-db
sudo apt-get purge -y --yes mtr-tiny
sudo apt-get purge -y --yes lshw
sudo apt-get purge -y --yes geoip-database
sudo apt-get purge -y --yes groff-base
sudo apt-get purge -y --yes fuse
sudo apt-get purge -y --yes update-manager-core
sudo apt-get purge -y --yes libtext-iconv-perl
sudo apt-get purge -y --yes libtext-charwidth-perl
sudo apt-get purge -y --yes unattended-upgrades
sudo apt-get purge -y --yes manpages
sudo apt-get purge -y --yes krb5-locales
sudo apt-get purge -y --yes cpp-7
sudo apt-get purge -y --yes language-pack-en
sudo apt-get purge -y --yes perl
sudo apt-get purge -y --yes libx11-data
sudo apt-get purge -y --yes xauth
sudo apt-get purge -y --yes libxmuu1
sudo apt-get purge -y --yes libxcb1
sudo apt-get purge -y --yes libx11-6
sudo apt-get purge -y --yes libxext6
sudo apt-get purge -y --yes ppp
sudo apt-get purge -y --yes pppconfig
sudo apt-get purge -y --yes pppoeconf
sudo apt-get purge -y --yes popularity-contest
sudo apt-get purge -y --yes installation-report
sudo apt-get purge -y --yes command-not-found
sudo apt-get purge -y --yes command-not-found-data
sudo apt-get purge -y --yes friendly-recovery
sudo apt-get purge -y --yes fonts-ubuntu-font-family-console
sudo apt-get purge -y --yes laptop-detect
sudo apt-get purge -y --yes gtk-update-icon-cache
sudo apt-get purge -y --yes adwaita-icon-theme
sudo apt-get purge -y --yes dosfstools
sudo apt-get purge -y --yes ftp
sudo apt-get purge -y --yes git-man
sudo apt-get purge -y --yes gnupg-utils
sudo apt-get purge -y --yes gpg
sudo apt-get purge -y --yes gpg-agent
sudo apt-get purge -y --yes gpg-wks-client
sudo apt-get purge -y --yes gpg-wks-server
sudo apt-get purge -y --yes gpgconf
sudo apt-get purge -y --yes gpgsm
sudo apt-get purge -y --yes gpgv
sudo apt-get purge -y --yes gpgv2
sudo apt-get purge -y --yes lvm2

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
sudo apt-get -y install deborphan
while [[ -n "$(deborphan --guess-all --libdevel)" ]]; do
    deborphan --guess-all --libdevel | xargs sudo apt-get -y purge
done
sudo apt-get -y purge deborphan

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
