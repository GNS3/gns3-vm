#!/bin/bash

sudo apt-get purge -y --yes vim-common
sudo apt-get purge -y --yes fonts-ubuntu-font-family-console
sudo apt-get purge -y --yes linux-headers-generic
sudo apt-get purge -y --yes linux-headers-virtual
sudo apt-get purge -y --yes vim-runtime
sudo apt-get purge -y --yes screen
sudo apt-get purge -y --yes tmux
sudo apt-get purge -y --yes memtest86+
sudo apt-get purge -y --yes usbutils
sudo apt-get purge -y --yes linux-firmware
sudo apt-get purge -y --yes wpasupplicant
sudo apt-get purge -y --yes wireless-tools
sudo apt-get purge -y --yes wireless-regdb
sudo apt-get purge -y --yes ppp
sudo apt-get purge -y --yes w3m
sudo apt-get purge -y --yes python2.7-minimal
sudo apt-get purge -y --yes man-db
sudo apt-get purge -y --yes sgml-base
sudo apt-get purge -y --yes mtr-tiny
sudo apt-get purge -y --yes lshw
sudo apt-get purge -y --yes geoip-database
sudo apt-get purge -y --yes groff-base
sudo apt-get purge -y --yes fuse
sudo apt-get purge -y --yes update-manager-core
sudo apt-get purge -y --yes ntpdate
sudo apt-get purge -y --yes apport
sudo apt-get purge -y --yes bc
sudo apt-get purge -y --yes aptitude
sudo apt-get purge -y --yes libtext-iconv-perl
sudo apt-get purge -y --yes libpython2.7-minimal
sudo apt-get purge -y --yes libapparmor-perl
sudo apt-get purge -y --yes libtext-charwidth-perl
sudo apt-get purge -y --yes unattended-upgrades
sudo apt-get purge -y --yes ntfs-3g
sudo apt-get purge -y --yes manpages
sudo apt-get purge -y --yes krb5-locales
sudo apt-get purge -y --yes git
sudo apt-get purge -y --yes cmake-data
sudo apt-get purge -y --yes cpp-4.9
sudo apt-get purge -y --yes language-pack-en
sudo apt-get purge -y --yes language-pack-gnome-en-base
sudo apt-get purge -y --yes perl

# Purge old kernels
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge

dpkg -l 'linux-headers-*' |grep '^ii'|sed 's/^ii[ ]*//'|cut -f1 -d' '| xargs sudo apt-get -y purge
dpkg -l 'linux-image-extra-*' |grep '^ii'|sed 's/^ii[ ]*//'|cut -f1 -d' '| xargs sudo apt-get -y purge


# Purge locale
sudo rm -Rf /usr/share/locale/*
sudo locale-gen --purge --lang en_US

# Tools for cleaning the disk
sudo apt-get install -y zerofree

sudo apt-get -y autoremove
sudo apt-get -y clean

sudo rm -fr /var/lib/apt/lists/*
sudo rm -fr /var/cache/apt/*
sudo rm -fr /var/cache/debconf/*
sudo rm -fr /var/cache/man/*
sudo rm -Rf /var/log/installer/*
sudo rm -Rf /usr/share/doc
sudo rm -Rf /var/lib/docker/devicemapper

sudo rm -rf /tmp/*

# Setup zerofree for disk compaction
sudo bash /usr/local/bin/zerofree
