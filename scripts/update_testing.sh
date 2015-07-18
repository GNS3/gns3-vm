#!/bin/bash
#
# Update script called from the GNS 3 VM
# 

set -e

sudo apt-get update
sudo apt-get upgrade -y

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/master/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"

# The upgrade from 0.8 to 0.8.1 is safe
if [ `cat .config/GNS3/gns3vm_version` = '0.8' ]
then
    echo -n '0.8.1' > .config/GNS3/gns3vm_version
fi
if [ `cat .config/GNS3/gns3vm_version` = '0.8.1' ]
then
    sudo apt-get install -y cpulimit
    echo -n '0.8.2' > .config/GNS3/gns3vm_version
fi

sudo pip3 install --pre --ignore-installed gns3-server 

echo "Reboot in 5s"
sleep 5

sudo reboot
