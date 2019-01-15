#!/bin/bash

# Used by the GNS3 restore command
export BRANCH="bionic-stable"
curl "https://raw.githubusercontent.com/GNS3/gns3-vm/$BRANCH/scripts/update_2.1.sh" | bash
