#!/bin/bash

export DEBIAN_FRONTEND=noninteractice 

dialog --title "Upgrade ubuntu" \
    --default-button no \
    --yesno "Are you sure you want to upgrade the ubuntu version? Make sure to snapshot before. The network configuration will be reset" \
    0 0
    

# Get exit status
# 0 means user hit [yes] button.
# 1 means user hit [no] button.
# 255 means user hit [Esc] key.
response=$?
case $response in
    0) echo "Upgrading...";;
    1) exit 0;;
    255) exit 0;;
esac

cat > /usr/local/bin/gns3restore << EOF
#!/bin/bash
#
# This command allow to rescue a broken installation of the
# GNS3 VM
#

if [[ $(id -u) -ne 0 ]]
then
    echo "Please run as root or with sudo"
    exit 1
fi

curl "https://raw.githubusercontent.com/GNS3/gns3-vm/16.10/scripts/restore.sh" | bash
EOF


cat > /etc/network/interface << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# Warning this file will be erased by each
# GNS3 VM update; if you want to customize it
# change the following var to 1 but DO NOT
# remove the leading #.
#
# MANUAL=0

# Host only interface
auto eth0

# Comment this line to disable DHCP
iface eth0 inet dhcp
# Uncomment this lines if you want to manually configure network
# It's not recommended if you can avoid it.
#
#iface eth0 inet static
#        address 10.10.10.10
#        netmask 255.255.0.0
#        gateway 10.10.0.1
#        dns-nameservers 8.8.8.8

# The loopback network interface
auto lo
iface lo inet loopback

# NAT interface
auto eth1
iface eth1 inet dhcp

# Optional bridge interace
auto eth2
iface eth2 inet dhcp
EOF

rm /etc/init/gns3.conf
rm /etc/init.d/network
rm /etc/network/if-up.d/gns3-ifup
do-release-upgrade -q  -f DistUpgradeViewNonInteractive 
reboot
