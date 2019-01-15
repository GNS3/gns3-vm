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

export BRANCH="bionic-stable"
export UNSTABLE_APT="0"

# upgrade the GNS3 VM first
curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade.sh" > /tmp/upgrade.sh && bash -x /tmp/upgrade.sh

# install the GNS3 server
if [ ! -d "gns3-server" ]
then
    sudo apt-get update
    sudo apt-get install -y git
    git clone https://github.com/GNS3/gns3-server.git gns3-server
fi

cd gns3-server
git reset --hard HEAD

if [ -z "$1" ]
then
  # get the latest tag for stable release of 2.1
  git fetch origin --tags
  LATEST_VERSION_TAG=`git tag -l 'v2.1*' | grep -v '[abr]' | sort -V | tail -n 1`
  git checkout $LATEST_VERSION_TAG
else
  git checkout $1
fi


sudo pip3 install -U -r requirements.txt
sudo python3 setup.py install

echo "Update completed, rebooting in 10 seconds..."
sleep 10
sudo reboot
