set -e

# Update system
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

sudo apt-get install -y curl

# netficaces
sudo apt-get install python3-netifaces

# Install dynamips
if [ -x /usr/local/bin/dynamips ]
then 
  echo "Dynamips is already installed skip compilation"
else
  sudo apt-get install -y cmake libelf-dev uuid-dev libpcap0.8-dev
  cd /tmp
  curl --silent "https://codeload.github.com/GNS3/dynamips/tar.gz/v0.2.14" > dynamips.tgz
  tar -xvzf dynamips.tgz
  cd dynamips-0.2.14/
  mkdir -p build
  cd build
  cmake ..
  sudo make install
fi

#Install VPCS
if [ -x /usr/local/bin/vpcs ]
then
  echo "VPCS is already installed skip download"  
else
  curl --silent 'http://kent.dl.sourceforge.net/project/vpcs/0.6/vpcs_0.6_Linux64' > vpcs
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

#Force hostid
sudo dd if=/dev/zero bs=4 count=1 of=/etc/hostid

# Setup Python 3
sudo apt-get install -y python3-pip

# Install GNS 3
sudo pip3 install gns3-server


#Dialog
sudo apt-get install -y dialog
sudo pip3 install pythondialog
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py" 
sudo chmod 700 "/usr/local/bin/gns3welcome.py"
echo "/usr/local/bin/gns3welcome.py" >> ~/.bash_profile


# Setup server
if [ -f ~/.config/GNS3/server.conf ]
then
    echo "GNS 3 configuration already exists"
else
    mkdir -p ~/.config/GNS3
    cat > ~/.config/GNS3/server.conf << EOF
[Server]
host = 0.0.0.0
port = 8000
images_path = /opt/gns3/images
projects_path = /opt/gns3/projects
EOF
fi

sudo mkdir -p /opt/gns3
sudo chown gns3 /opt/gns3

# Setup the message display on console
cat > /tmp/rc.local << EOFRC
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

IP=\$(ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1)
cat << EOF > /etc/issue
Welcome to GNS3 \$(gns3server --version) appliance
Use \$IP to configure a remote server in GNS3
Use your browser with http://\$IP:8000/upload to upload images

You can also ssh on the box with:
ssh gns3@\$IP
Password: gns3

Images and projects are located in /opt/gns3

\$(kvm-ok)
EOF

exit 0
EOFRC
sudo mv /tmp/rc.local /etc/rc.local
sudo chmod 700 /etc/rc.local
sudo chown root /etc/rc.local

# Setup upstart
cat > /tmp/gns3.conf << EOF
description "GNS3 server"
author      "GNS3 Team"

start on filesystem or runlevel [2345]
stop on shutdown

script
    echo \$\$ > /var/run/gns3.pid
    if [ ! -f /usr/local/bin/gns3server ]; then
        pip3 install gns3-server
    fi
    exec start-stop-daemon --start -c gns3 --exec /usr/local/bin/gns3server
end script

pre-start script
    echo "[\`date\`] GN3 Starting" >> /var/log/gns3.log
end script

pre-stop script
    rm /var/run/gns3.pid
    echo "[\`date\`] GNS3 Stopping" >> /var/log/gns3.log
end script
EOF

sudo mv /tmp/gns3.conf /etc/init/gns3.conf
sudo chown root /etc/init/gns3.conf
sudo service gns3 start
