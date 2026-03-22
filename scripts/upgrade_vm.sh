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

cd /tmp
sudo rm -Rf gns3-vm-*
echo "Download https://github.com/GNS3/gns3-vm/archive/${BRANCH}.tar.gz"
curl -Lk "https://github.com/GNS3/gns3-vm/archive/${BRANCH}.tar.gz" > gns3vm.tar.gz
tar -xzf gns3vm.tar.gz
rm gns3vm.tar.gz

# wait for dpkg/apt locks to be released
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   echo 'Waiting for the release of dpkg/apt locks...'
   sleep 5
done

# install required Ubuntu packages including GNS3 dependencies
cd gns3-vm-${BRANCH}/config
sudo -E bash -x install.sh

sudo dpkg --configure -a
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade -y

# upgrade the GNS3 welcome script
sudo -H pip3 install pythondialog bcrypt==4.1.2 --break-system-packages
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"

set +e
