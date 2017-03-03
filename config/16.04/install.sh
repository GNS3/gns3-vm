#!/bin/sh
#
# Copyright (C) 2015 GNS3 Technologies Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Install the config files on the system.
# This script need to run as root and you need to cd in
# the directory before running it
#

set -e

export DEBIAN_FRONTEND="noninteractive"

# Sources.list
cp sources.list /etc/apt/sources.list
chmod 644 /etc/apt/sources.list
chown root:root /etc/apt/sources.list

# Add our ppa
if [ ! -f /usr/bin/add-apt-repository ]
then
    apt-get update
    apt-get install -y software-properties-common
fi

if [ "$UNSTABLE_APT" == "1" ]
then
    add-apt-repository -y ppa:gns3/ppa
    add-apt-repository -y -r ppa:gns3/unstable
else
    add-apt-repository -y -r ppa:gns3/ppa
    add-apt-repository -y ppa:gns3/unstable
fi

dpkg --add-architecture i386
apt-get update

# VMware open-vm-tools
apt-get install -y open-vm-tools

# Autologin
apt-get install -y mingetty

# Python
apt-get install -y python3-dev python3.5-dev python3-setuptools

# Install netifaces
apt-get install -y python3-netifaces

# For nat interface
apt-get install -y libvirt-bin

# Install vpcs
apt-get install -y vpcs

# Install qemu
apt-get install -y qemu-system-x86 qemu-system-arm qemu-kvm cpulimit

# Install gns3 dependencies
apt-get install -y dynamips iouyap ubridge

# Install VNC support for Docker
apt-get install -y x11vnc xvfb

# Install iou dependencies
apt-get install -y gns3-iou 

# Setup Python 3
apt-get install -y python3-pip

cp "rc.local" "/etc/rc.local"
chmod 700 /etc/rc.local
chown root:root /etc/rc.local

# Setup dhclient
cp "dhclient.conf" "/etc/dhcp/dhclient.conf"
chown root:root /etc/dhcp/dhclient.conf
chmod 644 /etc/dhcp/dhclient.conf

# Setup grub
cp "grub" "/etc/default/grub"
chown root:root /etc/default/grub
chmod 700 /etc/default/grub
update-grub

# Workaround a bug in VMware suspend
# https://github.com/GNS3/gns3-vm/issues/82
cp "network-vmware-fix" "/etc/init.d/network"
chown root:root /etc/init.d/network
chmod 755 /etc/init.d/network

# Configure network
if [ -f /etc/network/interfaces ]
then
    # We need to detect if user has modify the config for eth0 (ESXi without vsphere)
    if grep -q 'MANUAL=1' /etc/network/interfaces
    then
        echo "User asked for not replacing /etc/network/interfaces"
    else
        cp interfaces /etc/network/interfaces
    fi
else
    cp interfaces /etc/network/interfaces
fi
chmod 644 /etc/network/interfaces
chown root:root /etc/network/interfaces

# Zerofree
cp zerofree /usr/local/bin/zerofree
chown root:root /usr/local/bin/zerofree
chmod 755 /usr/local/bin/zerofree

# Sysctl
cp sysctl.conf /etc/sysctl.conf
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

# Iptables
cp iptables /etc/network/if-pre-up.d/iptables
chmod 755 /etc/network/if-pre-up.d/iptables
chown root:root /etc/network/if-pre-up.d/iptables

# GNS3 Restore
cp gns3-restore.sh /usr/local/bin/gns3restore
chmod 755 /usr/local/bin/gns3restore
chown root:root /usr/local/bin/gns3restore

# Bash profile
cp bash_profile /home/gns3/.bash_profile
chmod 700 /home/gns3/.bash_profile
chown gns3:gns3 /home/gns3/.bash_profile

# ifup script
cp gns3-ifup /etc/network/if-up.d/gns3-ifup
chmod 755 /etc/network/if-up.d/gns3-ifup
chown root:root /etc/network/if-up.d/gns3-ifup

# System tuning for IOU
cp 50-qlen_gns3.conf /etc/sysctl.d/50-qlen_gns3.conf
chmod 755 /etc/sysctl.d/50-qlen_gns3.conf
chown root:root /etc/network/if-up.d/gns3-ifup

# Open GNS3 menu at startup
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cp tty.service /etc/systemd/system/getty@tty1.service.d/override.conf
chmod -R 755  /etc/systemd/system/getty@tty1.service.d/
chown -R root:root /etc/systemd/system/getty@tty1.service.d/

mkdir -p /etc/systemd/system/getty@tty2.service.d/
cp tty.service /etc/systemd/system/getty@tty2.service.d/override.conf
chmod -R 755 /etc/systemd/system/getty@tty2.service.d/
chown -R root:root /etc/systemd/system/getty@tty2.service.d/

# Install systemd service
cp gns3.service /lib/systemd/system/gns3.service
chmod 755 /lib/systemd/system/gns3.service
chown root:root /lib/systemd/system/gns3.service
systemctl enable gns3
