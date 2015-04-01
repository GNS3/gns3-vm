# Setup the ubuntu system
# This script should be run as root

# Enable eth1
echo "auto eth1" >> /etc/network/interfaces
echo "iface eth1 inet dhcp" >> /etc/network/interfaces


# Enable sudo without password
echo "gns3 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gns3

# Auto login
apt-get update
apt-get install mingetty

cat > /etc/init/tty1.conf <<EOF
# tty1 - getty
#
# This service maintains a getty on tty1 from the point the system is
# started until it is shut down again.

start on runlevel [23] and (
            not-container or
            container CONTAINER=lxc or
        container CONTAINER=lxc-libvirt)

stop on runlevel [!23]

respawn
exec /sbin/mingetty --autologin gns3 --noclear tty1
EOF

echo "Setup ubuntu OK"
