#!/bin/bash

# Installs GNS3 on a fresh VM

env

# wait for dpkg/apt locks to be released
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   echo 'Waiting for the release of dpkg/apt locks...'
   sleep 5
done

echo "${GNS3_VERSION}" | grep -E  "(dev|a|rc|b|unstable|master)"
if [[ $? -eq 0 ]]
then
  GNS3_PPA_URI="https://ppa.launchpadcontent.net/gns3/unstable/ubuntu"
else
  GNS3_PPA_URI="https://ppa.launchpadcontent.net/gns3/ppa/ubuntu"
fi

# Add the GNS3 PPA to the APT sources
sudo tee /etc/apt/sources.list.d/gns3-ppa.sources <<EOF
Types: deb
URIs: $(echo "${GNS3_PPA_URI}")
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/gns3-ppa.asc
EOF

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-dev gcc git ntp

# use the GNS3 server virtual environment
source /home/gns3/.venv/gns3server-venv/bin/activate

# upgrade pip, wheel and setuptools to the latest version
python3 -m pip install --upgrade pip wheel setuptools

# Exit immediately if a command exits with a non-zero status.
set -e

if [[ "$GNS3_VERSION" == "2.2" ]]
then
  # Install from a branch on GitHub
  python3 -m pip install "https://github.com/GNS3/gns3-server/archive/refs/heads/$GNS3_VERSION.zip"
elif [[ "$GNS3_VERSION" == "3.0" ]]
then
  python3 -m pip install gns3-server[ai-copilot]==${GNS3_VERSION}
  gns3server-web-wireshark-setup
elif [[ "$GNS3_VERSION" == "3.0dev" ]]
then
  python3 -m pip install "gns3-server[ai-copilot] @ git+https://github.com/GNS3/gns3-server.git@3.0"
  gns3server-web-wireshark-setup
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

sudo apt -y autoremove --purge
sudo apt -y clean

sudo rm -fr /var/lib/apt/lists/*
sudo rm -fr /var/cache/apt/*
sudo rm -fr /var/cache/debconf/*

# Defragment
sudo e4defrag / &>/dev/null

# Setup zerofree for disk compaction
sudo bash /usr/local/bin/zerofree
