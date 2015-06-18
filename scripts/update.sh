#!/bin/bash
#
# Update script called from the GNS 3 VM
# 

set -e

sudo apt-get update
sudo apt-get upgrade -y

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/master/scripts/welcome.py" > /tmp/gns3welcome.py
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 700 "/usr/local/bin/gns3welcome.py"

sudo pip3 install --ignore-installed gns3-server

sudo /etc/rc.local

# Setup upstart
cat > /tmp/gns3.conf << EOF
description "GNS3 server"
author      "GNS3 Team"

start on filesystem or runlevel [2345]
stop on runlevel [016]
respawn
console log


script
    if [ ! -f /usr/local/bin/gns3server ]; then
        pip3 install gns3-server
        /etc/rc.local
    fi
    exec start-stop-daemon --start --make-pidfile --pidfile /var/run/gns3.pid --chuid gns3 --exec "/usr/local/bin/gns3server"
end script

pre-start script
    echo "" > /var/log/upstart/gns3.log
    echo "[`date`] GNS3 Starting"
end script

pre-stop script
    echo "[`date`] GNS3 Stopping"
end script
EOF

sudo mv /tmp/gns3.conf /etc/init/gns3.conf
sudo chown root:root /etc/init/gns3.conf

echo "Reboot in 5s"
sleep 5
