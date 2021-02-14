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

export BRANCH="focal-stable"
export UNSTABLE_APT="0"

# upgrade the GNS3 VM first
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_vm.sh" > /tmp/upgrade_vm.sh && bash -x /tmp/upgrade_vm.sh

# install the GNS3 server
if [[ ! -d "gns3-server" ]]
then
    sudo apt-get update
    sudo apt-get install -y git
    git clone https://github.com/GNS3/gns3-server.git gns3-server

    # Make sure GCC is installed because psutil requires to be compiled
    # Maybe a wheel will be provided someday: https://github.com/giampaolo/psutil/issues/824
    sudo apt-get install -y gcc
fi

cd gns3-server
git reset --hard HEAD
git fetch origin --tags

if [[ -z "$1" ]]
then
  # get the latest tag for stable release of 2.1
  TAG=`git tag -l 'v2.1*' | grep -v '[abr]' | sort -V | tail -n 1`
else
  TAG=$1
fi
git checkout $TAG


if  [[ -z "$HTTP_PROXY" ]]
then
  sudo -H pip3 install -U -r requirements.txt
else
  sudo -H pip3 --proxy $HTTP_PROXY install -U -r requirements.txt
fi

sudo python3 setup.py install

echo "Upgrade to $TAG completed, rebooting in 10 seconds..."
sleep 10
sudo reboot
