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

# Exit immediately if a command exits with a non-zero status.
set -e

export DEBIAN_FRONTEND="noninteractive"

# Sources.list
cp sources.list /etc/apt/sources.list
chmod 644 /etc/apt/sources.list
chown root:root /etc/apt/sources.list

# Add the GNS3 PPA
if [[ ! -f /usr/bin/add-apt-repository ]]
then
    apt-get update
    apt-get install -y software-properties-common
fi

# use sudo -E to preserve proxy config
if [[ "$UNSTABLE_APT" == "1" ]]
then
    sudo -E add-apt-repository -y ppa:gns3/unstable
    add-apt-repository -y --remove ppa:gns3/ppa
else
    sudo -E add-apt-repository -y ppa:gns3/ppa
    add-apt-repository -y --remove ppa:gns3/unstable
fi

# for Qemu backports
sudo -E add-apt-repository -y ppa:gns3/qemu

# Allows to install 32-bit packages
# dpkg --add-architecture i386

apt-get update

# Install virt-what
apt-get install -y virt-what

# Autologin
apt-get install -y mingetty

# Python
apt-get install -y python3-dev python3-setuptools

# For the NAT node
apt-get install -y libvirt-bin

# Install Qemu
apt-get install -y qemu-system-x86 qemu-kvm cpulimit
sudo usermod -aG kvm gns3

# Install other GNS3 dependencies
apt-get install -y gns3-iou dynamips vpcs ubridge

# Install Docker
curl -sSLk https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce_18.06.1~ce~3-0~ubuntu_amd64.deb > /tmp/docker.deb
sudo apt-get install -y libltdl7
sudo dpkg -i /tmp/docker.deb
sudo usermod -aG docker gns3
sudo service docker stop
sudo rm -rf /var/lib/docker/aufs
# Necessary to prevent Docker from being blocked
systemctl mask systemd-networkd-wait-online.service

# Configure Docker to store its data in /opt/docker
cp "daemon.json" "/etc/docker/daemon.json"
chown root:root /etc/docker/daemon.json
chmod 644 /etc/docker/daemon.json

# Install VNC support for Docker
apt-get install -y tigervnc-standalone-server

# Prevent tigervnc to be uninstalled by cleaner.sh
apt-mark hold tigervnc-standalone-server

# Install pip
apt-get install -y python3-pip

# Install net-tools for ifconfig etc.
apt-get install -y net-tools

# Setup rc.local
cp "rc.local" "/etc/rc.local"
chmod 700 /etc/rc.local
chown root:root /etc/rc.local

# Setup netplan
cp "gns3vm_default_netcfg.yaml" "/etc/netplan/80_gns3vm_default_netcfg.yaml"
chown root:root /etc/netplan/80_gns3vm_default_netcfg.yaml
chmod 644 /etc/netplan/80_gns3vm_default_netcfg.yaml

# Do not overwrite user static network config
if [[ ! -f "/etc/netplan/90_gns3vm_static_netcfg.yaml" ]]
then
    cp "gns3vm_static_netcfg.yaml" "/etc/netplan/90_gns3vm_static_netcfg.yaml"
    chown root:root /etc/netplan/90_gns3vm_static_netcfg.yaml
    chmod 644 /etc/netplan/90_gns3vm_static_netcfg.yaml
fi

netplan apply

# Setup Grub
cp "grub" "/etc/default/grub"
chown root:root /etc/default/grub
chmod 700 /etc/default/grub
update-grub

# Setup KVM permissions
cp 60-qemu-system-common.rules /lib/udev/rules.d/60-qemu-system-common.rules
chmod 644 /lib/udev/rules.d/60-qemu-system-common.rules
chown root:root /lib/udev/rules.d/60-qemu-system-common.rules

# Setup Console
cp "console-setup" "/etc/default/console-setup"
chown root:root /etc/default/console-setup
chmod 644 /etc/default/console-setup

# Zerofree
cp zerofree /usr/local/bin/zerofree
chown root:root /usr/local/bin/zerofree
chmod 755 /usr/local/bin/zerofree

# Sysctl
cp sysctl.conf /etc/sysctl.conf
chmod 644 /etc/sysctl.conf
chown root:root /etc/sysctl.conf

# IPtables
cp iptables /etc/network/if-pre-up.d/iptables
chmod 755 /etc/network/if-pre-up.d/iptables
chown root:root /etc/network/if-pre-up.d/iptables

# GNS3 Restore
cp gns3-restore.sh /usr/local/bin/gns3restore
chmod 755 /usr/local/bin/gns3restore
chown root:root /usr/local/bin/gns3restore

# GNS3 VM
cp gns3-vm.sh /usr/local/bin/gns3vm
chmod 755 /usr/local/bin/gns3vm
chown root:root /usr/local/bin/gns3vm

# Bash profile
cp bash_profile /home/gns3/.bash_profile
chmod 700 /home/gns3/.bash_profile
chown gns3:gns3 /home/gns3/.bash_profile

# System tuning for IOU support
cp 50-qlen_gns3.conf /etc/sysctl.d/50-qlen_gns3.conf
chmod 755 /etc/sysctl.d/50-qlen_gns3.conf
chown root:root /etc/sysctl.d/50-qlen_gns3.conf

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

# Install GNS3 VM service
cp gns3vm.service /lib/systemd/system/gns3vm.service
chmod 755 /lib/systemd/system/gns3vm.service
chown root:root /lib/systemd/system/gns3vm.service
systemctl enable gns3vm
