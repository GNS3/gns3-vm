#!/bin/bash

export DEBIAN_FRONTEND="noninteractive"
export UBUNTU_RELEASE=`lsb_release -c -s`

# Exit immediately if a command exits with a non-zero status.
set -e

# Update the system
#sudo apt-get update
#sudo apt-get upgrade -y
#sudo apt-get dist-upgrade -y

# use the Ubuntu LTS enablement (also called HWE or Hardware Enablement) stack
# sudo apt-get install -y --install-recommends linux-generic-hwe-22.04

cd /tmp/config
sudo GNS3_RELEASE_CHANNEL="$GNS3_RELEASE_CHANNEL" bash install.sh

# Install the GNS3 VM menu dependency
sudo apt install -y cpu-checker dialog
sudo -H python3 -m pip install pythondialog bcrypt --break-system-packages

# Force the hostid for IOU license check
sudo dd if=/dev/zero bs=4 count=1 of=/etc/hostid

if [[ $PACKER_BUILDER_TYPE == "vmware-iso" || $PACKER_BUILDER_TYPE == "qemu" ]]
then
   # VMware open-vm-tools
   sudo apt install --yes open-vm-tools
fi

# Create the GNS3 folders
sudo mkdir -p /opt/gns3
sudo chown -R gns3:gns3 /opt/gns3

# Install the GNS3 VM menu
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"
