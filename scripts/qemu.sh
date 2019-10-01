#!/bin/bash
#
# Copyright (C) 2019 GNS3 Technologies Inc.
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

# Add the GNS3 PPA
if [[ ! $(which add-apt-repository) ]]
then
    apt-get update
    apt-get install -y software-properties-common
fi

if [[ -z "$1" ]]
then
  # default Qemu version is 3.1.0
  TAG="3.1.0"
else
  TAG=$1
fi

if [[ "$TAG" == "3.1.0" ]]
then
  sudo -E add-apt-repository -y ppa:gns3/qemu
else
  sudo add-apt-repository -y --remove ppa:gns3/qemu
fi

sudo apt-get purge -y "qemu*"
sudo apt-get update
sudo apt-get install -y qemu-system-x86 qemu-kvm cpulimit
sudo usermod -aG kvm gns3
echo "Qemu version $TAG has been installed"
sleep 10
