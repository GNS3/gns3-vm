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
# Upgrade VM to a new release
#

# Exit immediately if a command exits with a non-zero status.
set -e

export DEBIAN_FRONTEND="noninteractive"
export UBUNTU_VERSION=`lsb_release -r -s`

#FIXME: for development, we upgrade from the 18.04 branch
if [ "$UBUNTU_VERSION" == "18.04" ]
then
    export BRANCH="18.04"
fi

cd /tmp
rm -Rf gns3-vm-*
echo "Download https://github.com/GNS3/gns3-vm/archive/${BRANCH}.tar.gz"
curl --location "https://github.com/GNS3/gns3-vm/archive/${BRANCH}.tar.gz" > gns3vm.tar.gz
tar -xzf gns3vm.tar.gz
rm gns3vm.tar.gz

# install required Ubuntu packages including GNS3 dependencies
cd gns3-vm-${BRANCH}/config
sudo bash -x install.sh

sudo dpkg --configure -a
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y 

# upgrade the GNS3 welcome script
curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"

set +e

# The upgrade from 0.8 to 0.8.6 is safe
if [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.8' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.8.1' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.8.2' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.8.3' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.8.4' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.8.5' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.0' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.1' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.2' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.3' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.4' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.5' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.6' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.7' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.8' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.9' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.9.10' ]
then
    sudo apt-get -y dist-upgrade
    sudo usermod -a -G vde2-net gns3
    
    echo -n '0.10.0' > /home/gns3/.config/GNS3/gns3vm_version
fi

if [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.0' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.1' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.2' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.3' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.4' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.5' ]
then
    sudo rm -f /usr/local/bin/vpcs
    sed '/port = 8000$/d' -i /home/gns3/.config/GNS3/gns3_server.conf
    echo -n '0.10.6' > /home/gns3/.config/GNS3/gns3vm_version
fi

if [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.6' ]
then
    # It seem an upgrade of docker can leave dirty stuff
    sudo rm -rf /var/lib/docker/aufs
    echo -n '0.10.7' > /home/gns3/.config/GNS3/gns3vm_version    
fi

if [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.7' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.8' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.9' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.10' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.11' ] 
then
    echo -n '0.10.12' > /home/gns3/.config/GNS3/gns3vm_version
fi

if [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.12' ] \
    || [ `cat /home/gns3/.config/GNS3/gns3vm_version` = '0.10.13' ] 
then
    sudo apt-get remove -y docker docker-engine
    sudo rm /etc/apt/sources.list.d/*
    curl "https://download.docker.com/linux/ubuntu/dists/trusty/pool/stable/amd64/docker-ce_17.03.1~ce-0~ubuntu-trusty_amd64.deb" > /tmp/docker.deb
    sudo apt-get install -y libltdl7 libsystemd-journal0
    sudo dpkg -i /tmp/docker.deb
    echo -n '0.10.14' > /home/gns3/.config/GNS3/gns3vm_version
fi
