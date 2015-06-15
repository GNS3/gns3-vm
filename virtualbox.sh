#!/bin/bash

set -e

packer build -only=virtualbox-iso gns3.json
packer build -only=virtualbox-ovf gns3_compress.json