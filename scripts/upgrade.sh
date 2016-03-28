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

export DEBIAN_FRONTEND="noninteractive"

set -e

cd /tmp
rm -Rf gns3-vm-*
echo "Download https://github.com/GNS3/gns3-vm/archive/${BRANCH}.tar.gz"
curl --location "https://github.com/GNS3/gns3-vm/archive/${BRANCH}.tar.gz" > gns3vm.tar.gz
tar -xzf gns3vm.tar.gz
rm gns3vm.tar.gz
cd gns3-vm-${BRANCH}/config
sudo bash install.sh

sudo dpkg --configure -a
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y 

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"



cd ~

# The upgrade from 0.8 to 0.8.6 is safe
if [ `cat .config/GNS3/gns3vm_version` = '0.8' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.8.1' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.8.2' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.8.3' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.8.4' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.8.5' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.0' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.1' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.2' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.3' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.4' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.5' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.6' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.7' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.8' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.9' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.9.10' ]
then
    sudo apt-get -y dist-upgrade
    sudo usermod -a -G vde2-net gns3
    
    echo -n '0.10.0' > .config/GNS3/gns3vm_version
fi

if [ `cat .config/GNS3/gns3vm_version` = '0.10.0' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.10.1' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.10.2' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.10.3' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.10.4' ] \
    || [ `cat .config/GNS3/gns3vm_version` = '0.10.5' ]
then
    sudo rm -f /usr/local/bin/vpcs
    sed '/port = 8000$/d' -i ~/.config/GNS3/gns3_server.conf
    echo -n '0.10.5' > .config/GNS3/gns3vm_version
fi

