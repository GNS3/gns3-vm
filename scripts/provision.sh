export DEBIAN_FRONTEND="noninteractive"

set -e

# Update system
sudo apt-get update

sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y curl software-properties-common

cd /tmp/config
sudo bash install.sh

# Install & compile psutil because it's require c dependencies
sudo pip3 install psutil

# For the menu
sudo apt-get install -y dialog
sudo pip3 install pythondialog

# Block iou call. The server is down
echo "127.0.0.254 xml.cisco.com" | sudo tee --append /etc/hosts

# Force hostid for IOU
sudo dd if=/dev/zero bs=4 count=1 of=/etc/hostid

# Setup server
if [ -f ~/.config/GNS3/gns3_server.conf ]
then
    echo "Server is already configured"
else
    mkdir -p ~/.config/GNS3
    cat > ~/.config/GNS3/gns3_server.conf << EOF
[Server]
host = 0.0.0.0
images_path = /opt/gns3/images
projects_path = /opt/gns3/projects
report_errors = True
EOF
    if [ $PACKER_BUILDER_TYPE == "vmware-iso" ]
    then
        cat >> ~/.config/GNS3/gns3_server.conf << EOF

[Qemu]
enable_kvm = True
EOF
    else
        cat >> ~/.config/GNS3/gns3_server.conf << EOF

[Qemu]
enable_kvm = False
EOF
    fi
fi

# Create GNS3 folders
sudo mkdir -p /opt/gns3
sudo chown -R gns3:gns3 /opt/gns3

# Setup release flavor
echo -n "stable" > ~/.config/GNS3/gns3_release


# Menu
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"
