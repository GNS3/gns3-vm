export DEBIAN_FRONTEND="noninteractive"

set -e

# Update system
sudo apt-get update

sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y curl

cd /tmp/config
sudo bash install.sh

# VDE network
sudo usermod -a -G vde2-net gns3

#Install VPCS
if [ -x /usr/local/bin/vpcs ]
then
  echo "VPCS is already installed skip download"
else
  curl --location --silent 'https://github.com/GNS3/vpcs/releases/download/v0.8beta1/vpcs' > vpcs
  sudo mv vpcs /usr/local/bin/vpcs
  sudo chmod 755 /usr/local/bin/vpcs
fi

# Block iou call. The server is down
echo "127.0.0.254 xml.cisco.com" | sudo tee --append /etc/hosts

# Force hostid for IOU
sudo dd if=/dev/zero bs=4 count=1 of=/etc/hostid

# Install docker
curl -sSL https://get.docker.com > /tmp/docker.sh
sudo bash /tmp/docker.sh
sudo usermod -aG docker gns3

# Install & compile psutil because it's require c dependencies
sudo pip3 install psutil

# Setup server
if [ -f ~/.config/GNS3/gns3_server.conf ]
then
    echo "Server is already configured"
else
    mkdir -p ~/.config/GNS3
    cat > ~/.config/GNS3/gns3_server.conf << EOF
[Server]
host = 0.0.0.0
port = 8000
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


