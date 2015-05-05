#!/bin/bash
#
# Update script called from the GNS 3 VM
# 

set -e

curl "https://raw.githubusercontent.com/GNS3/gns3-packer/master/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 700 "/usr/local/bin/gns3welcome.py"

sudo pip3 install --upgrade gns3-server

sudo /etc/rc.local

echo "Reboot in 5s"
sleep 5
