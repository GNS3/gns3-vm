#!/bin/bash

# Used by the GNS3 restore command
export BRANCH="focal-stable"
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_2.2.sh" | bash