#!/bin/bash

# use the GNS3 server virtual environment and get the version
GNS3_VERSION=`source /home/gns3/.venv/gns3server-venv/bin/activate && python3 -m gns3server --version`

# used by the GNS3 restore command
export BRANCH="noble-stable"
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_3.0.sh $GNS3_VERSION" | bash
