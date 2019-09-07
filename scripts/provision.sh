#!/bin/bash

export DEBIAN_FRONTEND="noninteractive"

# Exit immediately if a command exits with a non-zero status.
set -e

# Update the system
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y curl software-properties-common

cd /tmp/config
sudo bash install.sh

# Install pip3 if missing
if [[ ! $(which pip3) ]]
then
  wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py && sudo python3 /tmp/get-pip.py
fi

# Install the GNS3 VM menu dependency
sudo apt-get install -y dialog
sudo pip3 install pythondialog

# Block IOU phone home call
echo "127.0.0.254 xml.cisco.com" | sudo tee --append /etc/hosts

# Force the hostid for IOU license check
sudo dd if=/dev/zero bs=4 count=1 of=/etc/hostid

# Configure the GNS3 server
if [[ -f ~/.config/GNS3/gns3_server.conf ]]
then
    echo "The GNS3 server is already configured"
else
    mkdir -p ~/.config/GNS3
    cat > ~/.config/GNS3/gns3_server.conf << EOF
[Server]
host = 0.0.0.0
images_path = /opt/gns3/images
projects_path = /opt/gns3/projects
report_errors = True
EOF

# Always activate KVM whatever the VM type
#    if [[ $PACKER_BUILDER_TYPE == "vmware-iso" ]]
#    then
#        cat >> ~/.config/GNS3/gns3_server.conf << EOF
#
#[Qemu]
#enable_kvm = True
#EOF
#    else
#        cat >> ~/.config/GNS3/gns3_server.conf << EOF
#
#[Qemu]
#enable_kvm = False
#EOF
#    fi

fi

if [[ $PACKER_BUILDER_TYPE == "vmware-iso" ]]
then
   # VMware open-vm-tools
   sudo apt-get install --yes open-vm-tools
fi

# Create the GNS3 folders
sudo mkdir -p /opt/gns3
sudo chown -R gns3:gns3 /opt/gns3

# Install the GNS3 VM menu
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"