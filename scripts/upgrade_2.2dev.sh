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

# Exit immediately if a command exits with a non-zero status.
set -e

export BRANCH="focal-unstable"
export UNSTABLE_APT="1"

# upgrade the GNS3 VM first
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_vm.sh" > /tmp/upgrade_vm.sh && bash -x /tmp/upgrade_vm.sh

# install the GNS3 server
if [[ ! -d "gns3-server" ]]
then
    sudo apt-get update
    sudo apt-get install -y git
    git clone https://github.com/GNS3/gns3-server.git gns3-server
fi

sudo chown -R gns3:gns3 gns3-server
cd gns3-server
sudo chmod -R 775 .git
git reset --hard HEAD
git fetch origin

if [[ -z "$1" ]] || [[ "$1" == "2.2" ]]
then
  git checkout "2.2" # latest dev version on this branch
  git pull
else
  git checkout $1
fi

# use the GNS3 server virtual environment
source /home/gns3/.venv/gns3server-venv/bin/activate

if  [[ -z "$HTTP_PROXY" ]]
then
  python3 -m pip install --upgrade pip setuptools
  python3 -m pip install -U -r requirements.txt
else
  python3 -m pip install --proxy $HTTP_PROXY --upgrade pip setuptools
  python3 -m pip install --proxy $HTTP_PROXY -U -r requirements.txt
fi

python3 -m pip install .

echo "Update to 2.2dev completed, rebooting in 10 seconds..."
sleep 10
sudo reboot
