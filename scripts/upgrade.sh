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
if [ `cat .config/GNS3/gns3vm_version` = '0.8.4' ] 
then
    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/rc.local" > /tmp/rc.local
    sudo mv /tmp/rc.local /etc/rc.local
    sudo chmod 700 /etc/rc.local
    sudo chown root:root /etc/rc.local
    echo -n '0.8.5' > .config/GNS3/gns3vm_version
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.8.5' ] 
then
    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/interfaces" > /tmp/interfaces
    sudo mv /tmp/interfaces /etc/network/interfaces
    sudo chmod 644 /etc/network/interfaces
    sudo chown root:root /etc/network/interfaces

    curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/config/grub" > /tmp/grub
    sudo mv /tmp/grub /etc/default/interfaces
    sudo chmod 644 /etc/default/grub
    sudo chown root:root /etc/default/grub
    sudo update-grub
fi
