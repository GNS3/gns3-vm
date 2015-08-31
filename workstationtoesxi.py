#!/usr/bin/env python
#
# Copyright (C) 2015 GNS3 Technologies Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""
This script will convert the workstation build to an ESXI compatible build.
Mainly it's dropping all networking specific stuff
"""

import os
import sys
import tempfile
import subprocess
from xml.etree import ElementTree as ET

if len(sys.argv) != 3:
    print("Usage: source.ova dst.ova")
    sys.exit(1)


with tempfile.TemporaryDirectory() as tmp_dir:
    print("Temporary directory: {}".format(tmp_dir))
    subprocess.call(["tar", "-xvzf", sys.argv[1], "-C", tmp_dir])
    tree = ET.parse(os.path.join(tmp_dir, 'GNS3 VM.ovf'))
    root = tree.getroot()

    # Drop nat network
    network_section = root.find("{http://schemas.dmtf.org/ovf/envelope/1}NetworkSection")
    for node in network_section.findall("{http://schemas.dmtf.org/ovf/envelope/1}Network"):
        if node.get("{http://schemas.dmtf.org/ovf/envelope/1}name") == "nat":
            network_section.remove(node)

    virtual_hardware = root.find("{http://schemas.dmtf.org/ovf/envelope/1}VirtualSystem/{http://schemas.dmtf.org/ovf/envelope/1}VirtualHardwareSection")
    nodes_to_remove = set()
    # Drop all extra config
    for child in root.iter('{http://www.vmware.com/schema/ovf}ExtraConfig'):
        print("Remove {}".format(child.attrib["{http://www.vmware.com/schema/ovf}key"]))
        nodes_to_remove.add(child)

    # Drop the second ethernet adapter
    for item in root.iter('{http://schemas.dmtf.org/ovf/envelope/1}Item'):
        connection = item.find('{http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData}Connection')
        if connection is not None and connection.text == "nat":
            print("Remove nat adapter")
            virtual_hardware.remove(item)

    for node in nodes_to_remove:
        virtual_hardware.remove(node)

    tree.write(os.path.join(tmp_dir, 'GNS3 VM.ovf'))
    subprocess.call(["ovftool", "--allowAllExtraConfig", "--overwrite", os.path.join(tmp_dir, 'GNS3 VM.ovf'), sys.argv[2]])

