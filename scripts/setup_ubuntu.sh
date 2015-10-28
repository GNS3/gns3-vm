# Setup the ubuntu system
# This script should be run as root


# Enable sudo without password
echo "gns3 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gns3

# Auto login
apt-get update

# Create the /opt disk
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
mkfs.ext4 /dev/sdb1
echo "/dev/sdb1  /opt  ext4  nodiratime  0  2" >> /etc/fstab
mount -a

echo "Setup ubuntu OK"
