#!/bin/bash

# Used to setup the migrate feature

# Generate a new key if it doesn't exist
if [ ! -f ~/.ssh/gns3-vm-key ]
then
    ssh-keygen -f ~/.ssh/gns3-vm-key -N ""
fi

# Copy the key to the remote GNS3 VM
ssh-copy-id -i ~/.ssh/gns3-vm-key gns3@$1
