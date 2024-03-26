#!/bin/bash

# Used by the GNS3 restore command
export BRANCH="noble-stable"
curl -Lk "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/upgrade_3.0.sh" | bash
