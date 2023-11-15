#!/usr/bin/env python
#
# Copyright (C) 2017 GNS3 Technologies Inc.
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
Utility script for managing devices on packet.net
"""

import sys
import time
import packet

token = sys.argv[1]
action = sys.argv[2]
packet_project = sys.argv[3]
server_type = sys.argv[4]
metro = sys.argv[5]

GNS3_HOSTNAME = 'gns3-vm-builder-{}'.format(server_type)


def get_device(project, hostname):
    devices = [d for d in manager.list_devices(project.id)
               if d.hostname == hostname]
    return len(devices) > 0 and devices[0] or None


manager = packet.Manager(auth_token=token)

gns3_projects = [p for p in manager.list_projects()
                 if p.name == packet_project]
if len(gns3_projects) > 0:
    gns3_project = gns3_projects[0]
else:
    sys.exit("Project `{}` doesn't exist on packet.net. Please create it.".format(packet_project))


def get():
    device = get_device(gns3_project, GNS3_HOSTNAME)

    if device is None:
        # create device
        device = manager.create_device(
            project_id=gns3_project.id,
            hostname=GNS3_HOSTNAME,
            plan=server_type,
            metro=metro,
            operating_system="ubuntu_22_04")

    # wait max 20 min for being active
    check_every = 5  # seconds
    for i in range(int(60*20/check_every)):
        if device is None:
            sys.exit("Device has been deleted during script execution.")

        if device.state in ['queued', 'provisioning']:
            time.sleep(check_every)
            device = get_device(gns3_project, GNS3_HOSTNAME)
        elif device.state == 'active':
            break
        else:
            sys.exit("Device is in wrong `{}` state.".format(device.state))

    public_addresses = ([a for a in device.ip_addresses
                         if a['address_family'] == 4 and a['public'] is True])

    if len(public_addresses) > 0:
        address = public_addresses[0]['address']
    else:
        sys.exit("Haven't found public addresses related to device.")

    print(address)


def destroy():
    device = get_device(gns3_project, GNS3_HOSTNAME)
    if device is not None:
        device.delete()


if action == 'get':
    get()
elif action == 'destroy':
    destroy()




