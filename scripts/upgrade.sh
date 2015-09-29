#!/bin/bash
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
# 
# Upgrade VM to a new release if require
#

set -e

sudo apt-get update
sudo apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"


cd ~

# The upgrade from 0.8 to 0.8.6 is safe
if [ `cat .config/GNS3/gns3vm_version` = '0.8' ] || [ `cat .config/GNS3/gns3vm_version` = '0.8.1' ]
then
    sudo apt-get install -y cpulimit
    echo -n '0.8.2' > .config/GNS3/gns3vm_version
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.8.2' ] || [ `cat .config/GNS3/gns3vm_version` = '0.8.3' ]
then    
    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/sources.list" > /tmp/sources.list
    sudo mv /tmp/sources.list /etc/apt/sources.list
    sudo chmod 644 /etc/apt/sources.list
    sudo chown root:root /etc/apt/sources.list
    echo -n '0.8.4' > .config/GNS3/gns3vm_version
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.8.4' ] || [ `cat .config/GNS3/gns3vm_version` = '0.8.5' ] 
then
    sudo apt-get install -y qemu-system-arm

    echo -n '0.9.0' > .config/GNS3/gns3vm_version
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.9.0' ] || [ `cat .config/GNS3/gns3vm_version` = '0.9.1' ]
then
    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/grub" > /tmp/grub
    sudo mv /tmp/grub /etc/default/grub
    sudo chmod 644 /etc/default/grub
    sudo chown root:root /etc/default/grub
    sudo update-grub

    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/rc.local" > /tmp/rc.local
    sudo mv /tmp/rc.local /etc/rc.local
    sudo chmod 700 /etc/rc.local
    sudo chown root:root /etc/rc.local

    cat > /etc/init/tty2.conf <<EOF
# tty2 - getty
#
# This service maintains a getty on tty1 from the point the system is
# started until it is shut down again.

start on runlevel [23] and (
            not-container or
            container CONTAINER=lxc or
        container CONTAINER=lxc-libvirt)

stop on runlevel [!23]

respawn
exec /sbin/mingetty --autologin gns3 --noclear tty2
EOF
    sudo apt-get install -y rsyslog
    sudo apt-get install -y xkb
    echo -n '0.9.2' > .config/GNS3/gns3vm_version
fi

if [ `cat .config/GNS3/gns3vm_version` = '0.9.2' ]
then
    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/rc.local" > /tmp/rc.local
    sudo mv /tmp/rc.local /etc/rc.local
    sudo chmod 700 /etc/rc.local
    sudo chown root:root /etc/rc.local

    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/dhclient.conf" > /tmp/dhclient.conf
    sudo mv "/tmp/dhclient.conf" "/etc/dhcp/dhclient.conf"
    sudo chown root:root /etc/dhcp/dhclient.conf
    sudo chmod 644 /etc/dhcp/dhclient.conf

    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/interfaces" > /tmp/interfaces
    sudo mv /tmp/interfaces /etc/network/interfaces
    sudo chmod 644 /etc/network/interfaces
    sudo chown root:root /etc/network/interfaces

    echo -n '0.9.3' > .config/GNS3/gns3vm_version    
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.9.3' ]
then
    curl --location --silent 'https://github.com/GNS3/vpcs/releases/download/v0.8beta1/vpcs' > vpcs
    sudo mv vpcs /usr/local/bin/vpcs
    sudo chmod 755 /usr/local/bin/vpcs

    echo -n '0.9.4' > .config/GNS3/gns3vm_version
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.9.4' ] || [ `cat .config/GNS3/gns3vm_version` = '0.9.5' ]
then
    sudo pip3 install --upgrade gns3-server==1.4.0b3
    echo -n '0.9.6' > .config/GNS3/gns3vm_version
fi

if [ `cat .config/GNS3/gns3vm_version` = '0.9.6' ]
then    
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:gns3/qemu 
    sudo apt-get update
    sudo apt-get -y dist-upgrade

    echo -n '0.9.7' > .config/GNS3/gns3vm_version
fi
    
