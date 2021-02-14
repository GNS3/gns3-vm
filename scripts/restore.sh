#!/bin/bash

# Used by the GNS3 restore command
export BRANCH="focal-unstable"
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_2.2dev.sh" | bash
