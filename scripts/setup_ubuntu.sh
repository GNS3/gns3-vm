# Setup the ubuntu system
# This script should be run as root

# Configure network
mv /tmp/sources.list /etc/apt/sources.list
chmod 644 /etc/apt/sources.list
chown root:root /etc/apt/sources.list

# Configure network
mv /tmp/interfaces /etc/network/interfaces
chmod 644 /etc/network/interfaces
chown root:root /etc/network/interfaces

# Enable sudo without password
echo "gns3 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gns3

# Auto login
apt-get update
apt-get install -y mingetty

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

cat > /etc/init/tty2.conf <<EOF
# tty2 - getty
#
# This service maintains a getty on tty1 from the point the system is
# started until it is shut down again.

start on runlevel [23] and (
            not-container or
            container CONTAINER=lxc or
        container CONTAINER=lxc-libvirt)

stop on runlevel [!23]

respawn
exec /sbin/mingetty --autologin gns3 --noclear tty2
EOF


# Create the /opt disk
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
mkfs.ext4 /dev/sdb1
echo "/dev/sdb1  /opt  ext4  nodiratime  0  2" >> /etc/fstab
mount -a

echo "Setup ubuntu OK"
