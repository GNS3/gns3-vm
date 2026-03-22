#!/bin/bash

# Installs GNS3 on a fresh VM

env

# wait for dpkg/apt locks to be released
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   echo 'Waiting for the release of dpkg/apt locks...'
   sleep 5
done

# Add the GNS3 PPA
if [[ ! $(which add-apt-repository) ]]
then
    sudo apt-get update
    sudo apt-get install -y software-properties-common
fi

echo "${GNS3_VERSION}" | grep -E  "(dev|a|rc|b|unstable|master)"
if [[ $? -eq 0 ]]
then
  sudo add-apt-repository -y -r ppa:gns3/ppa
  sudo add-apt-repository -y ppa:gns3/unstable
else
  sudo add-apt-repository -y -r ppa:gns3/unstable
  sudo add-apt-repository -y ppa:gns3/ppa
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-dev gcc git ntp

# use the GNS3 server virtual environment
source /home/gns3/.venv/gns3server-venv/bin/activate

# upgrade pip, wheel and setuptools to the latest version
python3 -m pip install --upgrade pip wheel setuptools

# Exit immediately if a command exits with a non-zero status.
set -e

if [[ "$GNS3_VERSION" == "master" || "$GNS3_VERSION" == "3.0" ]]
then
  # Install from a branch on GitHub
  python3 -m pip install "https://github.com/GNS3/gns3-server/archive/refs/heads/$GNS3_VERSION.zip"
else
  python3 -m pip install gns3-server==${GNS3_VERSION}
fi

set +e

# Configure the GNS3 server
mkdir -p "/opt/gns3/server"
cat > "/opt/gns3/server/gns3_server.conf" << EOF
[Server]
host = 0.0.0.0
port = 80
images_path = /opt/gns3/images
projects_path = /opt/gns3/projects
report_errors = True
EOF

# Make sure we have the latest version of the GNS3 VM menu
sudo mv "/tmp/gns3welcome.py" "/usr/local/bin/gns3welcome.py"
sudo chmod 755 "/usr/local/bin/gns3welcome.py"

sudo apt-get -y autoremove --purge
sudo apt-get -y clean

sudo rm -fr /var/lib/apt/lists/*
sudo rm -fr /var/cache/apt/*
sudo rm -fr /var/cache/debconf/*

# Defragment
sudo e4defrag / &>/dev/null

# Setup zerofree for disk compaction
sudo bash /usr/local/bin/zerofree
