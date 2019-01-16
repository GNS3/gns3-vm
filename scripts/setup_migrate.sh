#!/bin/bash

# Used to setup the migrate feature
ssh-keygen -f ~/.ssh/gns3-vm-key -q -P ""
ssh-copy-id -i ~/.ssh/gns3-vm-key gns3@$1
