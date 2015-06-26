set -e

# Update system
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y curl

# VMware open-vm-tools
sudo apt-get install -y open-vm-tools-lts-trusty

# Install dynamips
if [ -x /usr/local/bin/dynamips ]
then 
  echo "Dynamips is already installed skip compilation"
else
  sudo apt-get install -y cmake libelf-dev uuid-dev libpcap0.8-dev
  cd /tmp
  curl --location --silent "https://codeload.github.com/GNS3/dynamips/tar.gz/v0.2.14" > dynamips.tgz
  tar -xvzf dynamips.tgz
  cd dynamips-0.2.14/
  mkdir -p build
  cd build
  cmake ..
  sudo make install
  sudo setcap cap_net_raw,cap_net_admin+eip /usr/local/bin/dynamips
fi

#Install VPCS
if [ -x /usr/local/bin/vpcs ]
then
  echo "VPCS is already installed skip download"  
else
  curl --location --silent 'https://github.com/GNS3/vpcs/releases/download/v0.6.1/vpcs' > vpcs
  sudo mv vpcs /usr/local/bin/vpcs
  sudo chmod 755 /usr/local/bin/vpcs
fi

# Install qemu
sudo apt-get install -y qemu-system-x86 qemu-kvm

# Install iouyap
if [ -x /usr/local/bin/iouyap ]
then
  echo "iouyap is already installed skip download" 
else
  sudo apt-get install -y git bison flex
  cd /tmp
  git clone http://github.com/ndevilla/iniparser.git
  cd iniparser
  make
  sudo cp libiniparser.* /usr/lib/
  sudo cp src/iniparser.h /usr/local/include
  sudo cp src/dictionary.h /usr/local/include
  cd ..

  git clone https://github.com/GNS3/iouyap.git
  cd iouyap
  make
  sudo make install
fi

# Install iou dependencies
sudo apt-get install -y lib32z1
sudo apt-get install -y libssl1.0.0
sudo apt-get install -y 'libssl1.0.0:i386'

if [ -f /lib/i386-linux-gnu/libcrypto.so.4 ]
then
    echo "Libcrypto is already installed"
else
    sudo ln -s /lib/i386-linux-gnu/libcrypto.so.1.0.0 /lib/i386-linux-gnu/libcrypto.so.4
fi

echo "127.0.0.254 xml.cisco.com" | sudo tee --append /etc/hosts

# Install docker
curl -sSL https://get.docker.com > /tmp/docker.sh
sudo bash /tmp/docker.sh
sudo usermod -aG docker gns3

# Force hostid
sudo dd if=/dev/zero bs=4 count=1 of=/etc/hostid

# Setup Python 3
sudo apt-get install -y python3-pip

# Install netifaces
sudo apt-get install python3-netifaces

# Install GNS 3
sudo pip3 install gns3-server

# Dialog
sudo apt-get install -y dialog
sudo pip3 install pythondialog
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py" 
sudo chmod 700 "/usr/local/bin/gns3welcome.py"
echo "/usr/local/bin/gns3welcome.py" >> ~/.bash_profile


# Setup server
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


sudo mkdir -p /opt/gns3
sudo chown gns3:gns3 /opt/gns3

# Setup the message display on console
sudo mv "/tmp/rc.local" "/etc/rc.local" 
sudo chmod 700 /etc/rc.local
sudo chown root:root /etc/rc.local

# Setup grub
sudo mv "/tmp/grub" "/etc/default/grub" 
sudo chown root:root /etc/default/grub
sudo update-grub

# Setup upstart
sudo mv "/tmp/gns3.conf" "/etc/init/gns3.conf" 
sudo chown root:root /etc/init/gns3.conf
sudo service gns3 start
