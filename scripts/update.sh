#!/bin/bash
#
# Update script called from the GNS 3 VM
# 

sudo pip3 install --upgrade gns3-server

echo "Reboot in 5s"
sleep 5

sudo reboot
