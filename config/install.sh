#!/bin/bash
#
# Copyright (C) 2022 GNS3 Technologies Inc.
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
export UBUNTU_RELEASE=`lsb_release -c -s`

#################
## APT sources ##
#################

# Do not install recommended/suggested packages by default to save disk space
tee > /etc/apt/apt.conf.d/99-no-install-recommends <<EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

if [[ "$(dpkg --print-architecture)" == "arm64" ]]
then

# Use the Ubuntu ports repository for arm64 and the main repository for amd64
tee /etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
Architectures: arm64

Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
Architectures: arm64

Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
Architectures: amd64

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
Architectures: amd64
EOF

# Activate amd64 for IOU support
dpkg --add-architecture amd64

fi

# Add the GNS3 PPA official GPG key
if [[ ! -f "/etc/apt/keyrings/gns3-ppa.asc" ]]
then
  apt update
  apt install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB83AAABFFBD82D21B543C8EA86C22C2EC6A24D7F' -o /etc/apt/keyrings/gns3-ppa.asc
  chmod a+r /etc/apt/keyrings/gns3-ppa.asc
fi

echo "Adding GNS3 PPA for release channel $GNS3_RELEASE_CHANNEL"

if [[ "$UNSTABLE_APT" == "1" ]]
then
  if [[ "$GNS3_RELEASE_CHANNEL" == "2.2" ]]
  then
    GNS3_PPA_URI="https://ppa.launchpadcontent.net/gns3/unstable/ubuntu"
  else
    GNS3_PPA_URI="https://ppa.launchpadcontent.net/gns3/unstable-v3/ubuntu"
  fi
else
    if [[ "$GNS3_RELEASE_CHANNEL" == "2.2" ]]
  then
    GNS3_PPA_URI="https://ppa.launchpadcontent.net/gns3/ppa/ubuntu"
  else
    GNS3_PPA_URI="https://ppa.launchpadcontent.net/gns3/ppa-v3/ubuntu"
  fi
fi

# Add the GNS3 PPA to the APT sources
tee /etc/apt/sources.list.d/gns3-ppa.sources <<EOF
Types: deb
URIs: $(echo "${GNS3_PPA_URI}")
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/gns3-ppa.asc
EOF

# Add the Docker official GPG key
if [[ ! -f "/etc/apt/keyrings/docker.asc" ]]
then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

# Add the Docker repository to the APT sources
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update

# Install jq for upgrades
apt install -y jq

# Install virt-what
apt install -y virt-what

# Autologin
apt install -y mingetty

# Python
apt install -y python3-minimal python3-venv python3-pip

# Create virtualenv for gns3server
if [[ ! -d "/home/gns3/.venv/gns3server-venv" ]]
then
  python3 -m venv /home/gns3/.venv/gns3server-venv
  sudo chown -R gns3:gns3 /home/gns3/.venv
fi

# For the NAT node
apt install -y libvirt-daemon-system

# For admin password reset in the controller database
apt install -y sqlite3

##################
## Qemu support ##
##################

# Install Qemu
apt install -y qemu-system-x86 qemu-utils cpulimit swtpm
sudo usermod -aG kvm gns3

# GNS3 projects directory in the VM is located on a different partition than the partition for the root directory (/)
# additional permissions need to be configured for swtpm in AppArmor
echo "owner /opt/gns3/** rwk," | sudo tee /etc/apparmor.d/local/usr.bin.swtpm > /dev/null
sudo service apparmor restart

# Fix the KVM high CPU usage with some appliances
# See https://github.com/GNS3/gns3-vm/issues/128
if [[ ! $(cat /etc/modprobe.d/qemu-system-x86.conf | grep "halt_poll_ns") ]]; then
   echo "options kvm halt_poll_ns=0" | sudo tee --append /etc/modprobe.d/qemu-system-x86.conf
fi

# Setup KVM permissions
cp 60-qemu-system-common.rules /lib/udev/rules.d/60-qemu-system-common.rules
chmod 644 /lib/udev/rules.d/60-qemu-system-common.rules
chown root:root /lib/udev/rules.d/60-qemu-system-common.rules

####################
## Docker support ##
####################

# Install Docker
set +e  # avoid service error on arm64
apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker gns3
sudo service docker stop
sudo rm -rf /var/lib/docker/aufs
# Necessary to prevent Docker from being blocked
systemctl mask systemd-networkd-wait-online.service
set -e

# Configure Docker to store its data in /opt/docker
cp "daemon.json" "/etc/docker/daemon.json"
chown root:root /etc/docker/daemon.json
chmod 644 /etc/docker/daemon.json

# Install VNC support for Docker
apt install -y tigervnc-standalone-server

#################
## IOU support ##
#################

if [[ "$(dpkg --print-architecture)" == "arm64" ]]
then
  # Install Qemu user emulation with binfmt_misc on arm64 (for IOU support)
  apt install -y binfmt-support qemu-user qemu-user-binfmt
  apt install -y libc6:i386 libc6:amd64
  apt install -y gns3-iou:amd64
fi

# System tuning for IOU support
cp 50-qlen_gns3.conf /etc/sysctl.d/50-qlen_gns3.conf
chmod 755 /etc/sysctl.d/50-qlen_gns3.conf
chown root:root /etc/sysctl.d/50-qlen_gns3.conf

########################################
## XRd (containerized IOS XR) support ##
########################################

cp 99-gns3-xrd.conf /etc/sysctl.d/99-gns3-xrd.conf
chmod 644 /etc/sysctl.d/99-gns3-xrd.conf
chown root:root /etc/sysctl.d/99-gns3-xrd.conf
sysctl -p /etc/sysctl.d/99-gns3-xrd.conf || true

# Load the FUSE kernel module at boot (required by XRd, /dev/fuse)
mkdir -p /etc/modules-load.d
cp fuse.conf /etc/modules-load.d/fuse.conf
chmod 644 /etc/modules-load.d/fuse.conf
chown root:root /etc/modules-load.d/fuse.conf
modprobe fuse || true

####################
## Network config ##
####################

# Setup netplan
cp "gns3vm_default_netcfg.yaml" "/etc/netplan/80_gns3vm_default_netcfg.yaml"
chown root:root /etc/netplan/80_gns3vm_default_netcfg.yaml
chmod 600 /etc/netplan/80_gns3vm_default_netcfg.yaml

# Do not overwrite user static network config
if [[ ! -f "/etc/netplan/90_gns3vm_static_netcfg.yaml" ]]
then
    cp "gns3vm_static_netcfg.yaml" "/etc/netplan/90_gns3vm_static_netcfg.yaml"
    chown root:root /etc/netplan/90_gns3vm_static_netcfg.yaml
    chmod 600 /etc/netplan/90_gns3vm_static_netcfg.yaml
fi

# Install other GNS3 dependencies
apt install -y dynamips vpcs ubridge mtools

# Install tshark for packet capture
apt-get install -y tshark

# Setup rc.local
cp "rc.local" "/etc/rc.local"
chmod 700 /etc/rc.local
chown root:root /etc/rc.local

# Setup Grub
cp "grub" "/etc/default/grub"
chown root:root /etc/default/grub
chmod 700 /etc/default/grub
update-grub

# Setup libvirt network
if virsh net-info default | grep -q '^Active:.*yes'; then
    virsh net-undefine default || true
    virsh net-destroy default
fi

if [[ ! -f "/etc/libvirt/qemu/networks/gns3.xml" ]]
then
    cp gns3.xml /etc/libvirt/qemu/networks/gns3.xml
    virsh net-define /etc/libvirt/qemu/networks/gns3.xml
    virsh net-autostart gns3
fi

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

# Open GNS3 menu at startup
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cp tty.service /etc/systemd/system/getty@tty1.service.d/override.conf
chmod -R 755  /etc/systemd/system/getty@tty1.service.d/
chown -R root:root /etc/systemd/system/getty@tty1.service.d/

mkdir -p /etc/systemd/system/getty@tty2.service.d/
cp tty.service /etc/systemd/system/getty@tty2.service.d/override.conf
chmod -R 755 /etc/systemd/system/getty@tty2.service.d/
chown -R root:root /etc/systemd/system/getty@tty2.service.d/

# Install GNS3 systemd service
cp gns3.service /lib/systemd/system/gns3.service
chmod 755 /lib/systemd/system/gns3.service
chown root:root /lib/systemd/system/gns3.service
systemctl enable gns3

# Install GNS3 VM systemd service
cp gns3vm.service /lib/systemd/system/gns3vm.service
chmod 755 /lib/systemd/system/gns3vm.service
chown root:root /lib/systemd/system/gns3vm.service
systemctl enable gns3vm

# Install SNMP agent but disable on boot
apt install -y snmpd
systemctl disable snmpd

# Install NTP client
apt install -y chrony

# Disable cloud-init
touch /etc/cloud/cloud-init.disabled

# Restart systemd services
#systemctl daemon-reload
#systemctl restart gns3.service
#systemctl restart gns3vm.service
