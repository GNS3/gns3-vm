#!/bin/bash

export PATH=$PATH:/Applications/VMware\ OVF\ Tool/
set -e

rm -Rf output-vmware-vmx
packer build -only=vmware-iso gns3.json
packer build -only=vmware-vmx gns3_compress.json

ovftool --overwrite output-vmware-vmx/GNS3\ VM.vmx GNS3\ VM.ova
