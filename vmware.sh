#!/bin/bash

set -e

packer build -only=vmware-iso gns3.json
packer build -only=vmware-vmx gns3_compress.json
