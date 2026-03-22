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

export BRANCH="noble-unstable"
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

if [[ -z "$1" ]] || [[ "$1" == "3.0" ]]
then
  git checkout "3.0" # latest dev version on this branch
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

# update the web-ui as well
if [[ -z "$1" ]] || [[ "$1" == "3.0" ]]
then
  cd ..
  if [[ ! -d "gns3-web-ui" ]]
  then
    git clone https://github.com/GNS3/gns3-web-ui.git gns3-web-ui
  fi
  sudo chown -R gns3:gns3 gns3-web-ui
  cd gns3-web-ui
  sudo chmod -R 775 .git
  git reset --hard HEAD
  git fetch origin
  git checkout "master-3.0"
  git pull
  WEB_UI_PATH=$(dirname `python3 -c "import gns3server; print(gns3server.__file__)"`)/static/web-ui
  sudo rm -rf $WEB_UI_PATH/*
  sudo cp -R dist/* $WEB_UI_PATH
  echo "Development Web-Ui installed"
fi

echo "Update to 3.0dev completed, rebooting in 10 seconds..."
sleep 10
sudo reboot
