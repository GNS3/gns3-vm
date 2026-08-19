#!/bin/bash

# reboot to finish installing a new kernel
sudo systemctl stop sshd.service
sudo nohup shutdown -r now < /dev/null > /dev/null 2>&1 &
exit 0
