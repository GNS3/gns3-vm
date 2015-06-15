#!/bin/bash
#
# Update script called from the GNS 3 VM
# 

set -e

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/master/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 700 "/usr/local/bin/gns3welcome.py"

cd ~
if [ ! -d "gns3-server" ]
then 
    sudo apt-get install -y git
    git clone https://github.com/GNS3/gns3-server.git gns3-server
fi

cd gns3-server
git fetch origin
git checkout master
git pull -u
sudo python3 setup.y install

echo "Reboot in 5s"
sleep 5

sudo reboot
