#!/bin/bash

# Installs GNS3 on a fresh VM

env

# wait for dpkg/apt locks to be released
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   echo 'Waiting for the release of dpkg/apt locks...'
   sleep 5
done

# use the GNS3 server virtual environment
source /home/gns3/.venv/gns3server-venv/bin/activate

# upgrade pip, wheel and setuptools to the latest version
python3 -m pip install --upgrade pip wheel setuptools

# Exit immediately if a command exits with a non-zero status.
set -e

if [[ "$GNS3_RELEASE_CHANNEL" == "2.2" ]]
then
  # Install from a branch on GitHub
  echo "Installing GNS3 server $GNS3_VERSION from GitHub"
  python3 -m pip install "gns3-server@git+https://github.com/GNS3/gns3-server.git@v$GNS3_VERSION"
elif [[ "$GNS3_RELEASE_CHANNEL" == "3.1" ]]
then
  echo "Installing GNS3 server $GNS3_VERSION from PyPI"
  python3 -m pip install gns3-server[ai-copilot]==${GNS3_VERSION}
elif [[ "$GNS3_RELEASE_CHANNEL" == "3.1dev" ]]
then
  echo "Installing GNS3 server dev $GNS3_VERSION from GitHub"
  python3 -m pip install "gns3-server[ai-copilot]@git+https://github.com/GNS3/gns3-server.git@3.1"
fi

# clean pip cache to reduce the size of the VM
python3 -m pip cache info
python3 -m pip cache purge

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

if [[ $PACKER_BUILDER_TYPE == "vmware-iso" || $PACKER_BUILDER_TYPE == "qemu" ]]
then
   sudo vmware-toolbox-cmd disk shrink /
fi
