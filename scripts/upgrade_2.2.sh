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

export BRANCH="noble-stable"
export UNSTABLE_APT="0"
export PYPI_GNS3SERVER_JSON_URL="https://pypi.org/pypi/gns3-server/json"

# upgrade the GNS3 VM first
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_vm.sh" > /tmp/upgrade_vm.sh && bash -x /tmp/upgrade_vm.sh

# install the GNS3 server
if [[ -z "$1" ]]
then
  # get the latest stable release of channel 2.2
  RELEASE=`curl -Lk "$PYPI_GNS3SERVER_JSON_URL" | jq  -r '.releases | keys | .[]' | grep -E '^2.2' | grep -v '[abrd]' | sort -V | tail -n 1`
else
  RELEASE=$1
fi

# use the GNS3 server virtual environment
source /home/gns3/.venv/gns3server-venv/bin/activate

if  [[ -z "$HTTP_PROXY" ]]
then
  python3 -m pip install --upgrade pip setuptools
  python3 -m pip install gns3-server==$RELEASE
else
  python3 -m pip install --proxy $HTTP_PROXY --upgrade pip setuptools
  python3 -m pip install --proxy $HTTP_PROXY gns3-server==$RELEASE
fi

echo "Upgrade to $RELEASE completed, rebooting in 10 seconds..."
sleep 10
sudo reboot
