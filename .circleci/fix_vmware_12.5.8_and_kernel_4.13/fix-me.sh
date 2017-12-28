#!/bin/bash

# uses: https://communities.vmware.com/thread/568089
# and: https://raw.githubusercontent.com/mkubecek/vmware-host-modules/b50848c985f1a6c0a341187346d77f0119d0a835/vmmon-only/linux/hostif.c

sudo mkdir /lib/modules/`uname -r`/misc

sudo rm -rf /usr/lib/vmware/modules/source/vmmon-only/
sudo rm -rf /usr/lib/vmware/modules/source/vmnet-only/

sudo tar -xvf /usr/lib/vmware/modules/source/vmmon.tar --directory /usr/lib/vmware/modules/source
sudo tar -xvf /usr/lib/vmware/modules/source/vmnet.tar --directory /usr/lib/vmware/modules/source

cd /usr/lib/vmware/modules/source/vmnet-only/

sudo patch < /root/VMware-Workstation-12.5.7-kernel4.13-atomic-inc.patch
sudo make

sudo cp -p vmnet.ko /lib/modules/`uname -r`/misc

cd /usr/lib/vmware/modules/source/vmmon-only/

sudo cp -p /root/hostif.c /usr/lib/vmware/modules/source/vmmon-only/linux/hostif.c
sudo make
sudo cp -p vmmon.ko /lib/modules/`uname -r`/misc

sudo depmod -a

/etc/init.d/vmware restart