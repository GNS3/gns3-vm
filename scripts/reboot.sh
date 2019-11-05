#!/bin/bash

# reboot to finish installing a new kernel

systemctl stop sshd.service
nohup shutdown -r now < /dev/null > /dev/null 2>&1 &
exit 0
