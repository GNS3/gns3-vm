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

"""Provision and terminate job-scoped EC2 builders using standard AWS credentials."""

import argparse
import hashlib
import os
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError


MANAGED_BY = 'gns3-vm-circleci'
HEARTBEAT_FILE = '/var/lib/gns3-builder/heartbeat'
# CircleCI skips "when: always" steps on cancelled jobs, so the builder shuts
# itself down (terminating it) once the job stops sending heartbeats.
USER_DATA = """#!/bin/bash
set -eu
mkdir -p /var/lib/gns3-builder
touch /var/lib/gns3-builder/booted
cat > /usr/local/sbin/gns3-builder-watchdog <<'EOF'
#!/bin/bash
now=$(date +%s)
if [ -f {heartbeat} ]; then
  last=$(stat -c %Y {heartbeat})
  limit=600
else
  last=$(stat -c %Y /var/lib/gns3-builder/booted)
  limit=1800
fi
if [ $((now - last)) -gt "$limit" ]; then
  logger -t gns3-builder-watchdog "No CircleCI heartbeat, shutting down"
  /sbin/shutdown -h now
fi
EOF
chmod 755 /usr/local/sbin/gns3-builder-watchdog
systemd-run --unit=gns3-builder-watchdog --on-active=1min --on-unit-active=1min \\
  /usr/local/sbin/gns3-builder-watchdog
systemd-run --unit=gns3-builder-shutdown --on-active=90m /sbin/shutdown -h now
""".format(heartbeat=HEARTBEAT_FILE)


def required_env(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError('Required environment variable {} is not set.'.format(name))
    return value


def find_instances(ec2, build_id):
    pages = ec2.get_paginator('describe_instances').paginate(Filters=[
        {'Name': 'tag:ManagedBy', 'Values': [MANAGED_BY]},
        {'Name': 'tag:BuildID', 'Values': [build_id]},
        {'Name': 'instance-state-name',
         'Values': ['pending', 'running', 'stopping', 'stopped', 'shutting-down']},
    ])
    return [instance for page in pages
            for reservation in page['Reservations']
            for instance in reservation['Instances']]


def launch_instance(ec2, build_id):
    architecture = required_env('EC2_ARCHITECTURE')
    defaults = {'x86_64': 'c5n.metal', 'arm64': 'c6g.metal'}
    if architecture not in defaults:
        raise RuntimeError('EC2_ARCHITECTURE must be x86_64 or arm64.')
    instance_type = os.environ.get('EC2_INSTANCE_TYPE_' + architecture.upper(),
                                   defaults[architecture])
    details = ec2.describe_instance_types(
        InstanceTypes=[instance_type])['InstanceTypes'][0]
    if (not details['BareMetal'] or
           architecture not in details['ProcessorInfo']['SupportedArchitectures']):
       raise RuntimeError('Instance type must be bare metal and support {}.'.format(architecture))

    image_id = os.environ.get('EC2_AMI_ID_' + architecture.upper())
    if image_id:
        images = ec2.describe_images(ImageIds=[image_id])['Images']
    else:
        image_arch = 'amd64' if architecture == 'x86_64' else 'arm64'
        images = ec2.describe_images(
            Owners=['099720109477'],
            Filters=[
                {'Name': 'name', 'Values': [
                    'ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-{}-server-*'.format(image_arch)]},
                {'Name': 'architecture', 'Values': [architecture]},
                {'Name': 'state', 'Values': ['available']},
                {'Name': 'root-device-type', 'Values': ['ebs']},
                {'Name': 'virtualization-type', 'Values': ['hvm']},
            ])['Images']
    if not images:
        raise RuntimeError('No Ubuntu 24.04 AMI found in this AWS region.')
    image = max(images, key=lambda candidate: candidate['CreationDate'])
    if image['Architecture'] != architecture or image['RootDeviceType'] != 'ebs':
        raise RuntimeError('AMI must be EBS-backed and match EC2_ARCHITECTURE.')

    volume_size = int(os.environ.get('EC2_VOLUME_SIZE', '200'))
    root_size = next(mapping['Ebs']['VolumeSize']
                     for mapping in image['BlockDeviceMappings']
                     if mapping['DeviceName'] == image['RootDeviceName'])
    if volume_size < root_size:
        raise RuntimeError('EC2_VOLUME_SIZE is smaller than the AMI root volume.')

    tags = [
        {'Key': 'Name', 'Value': 'gns3-vm-builder-' + architecture},
        {'Key': 'ManagedBy', 'Value': MANAGED_BY},
        {'Key': 'BuildID', 'Value': build_id},
    ]
    response = ec2.run_instances(
        ImageId=image['ImageId'],
        InstanceType=instance_type,
        KeyName=required_env('EC2_KEY_NAME'),
        MinCount=1,
        MaxCount=1,
        ClientToken=hashlib.sha256(build_id.encode()).hexdigest(),
        NetworkInterfaces=[{
            'DeviceIndex': 0,
            'SubnetId': required_env('EC2_SUBNET_ID'),
            'Groups': [required_env('EC2_SECURITY_GROUP_ID')],
            'AssociatePublicIpAddress': True,
            'DeleteOnTermination': True,
        }],
        BlockDeviceMappings=[{
            'DeviceName': image['RootDeviceName'],
            'Ebs': {'VolumeSize': volume_size, 'VolumeType': 'gp3',
                    'DeleteOnTermination': True, 'Encrypted': True},
        }],
        MetadataOptions={'HttpTokens': 'required', 'HttpEndpoint': 'enabled'},
        InstanceInitiatedShutdownBehavior='terminate',
        UserData=USER_DATA,
        TagSpecifications=[
            {'ResourceType': 'instance', 'Tags': tags},
            {'ResourceType': 'volume', 'Tags': tags},
        ],
    )
    return response['Instances'][0]


def get(ec2, build_id):
    instances = find_instances(ec2, build_id)
    if len(instances) > 1:
        raise RuntimeError('Multiple EC2 builders found for this job; run destroy.')
    instance = instances[0] if instances else launch_instance(ec2, build_id)
    if instance['State']['Name'] not in ['pending', 'running']:
        raise RuntimeError('EC2 builder is not pending or running; run destroy.')
    instance_id = instance['InstanceId']
    ec2.get_waiter('instance_status_ok').wait(
        InstanceIds=[instance_id], IncludeAllInstances=True,
        WaiterConfig={'Delay': 10, 'MaxAttempts': 120})
    instance = ec2.describe_instances(
        InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
    if not instance.get('PublicIpAddress'):
        raise RuntimeError('EC2 builder has no public IPv4 address.')
    print(instance['PublicIpAddress'])


def destroy(ec2, build_id):
    instances = find_instances(ec2, build_id)
    to_terminate = [instance['InstanceId'] for instance in instances
                    if instance['State']['Name'] != 'shutting-down']
    if to_terminate:
        ec2.terminate_instances(InstanceIds=to_terminate)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['get', 'destroy'])
    args = parser.parse_args()
    try:
        build_id = os.environ.get('EC2_BUILD_ID') or required_env('CIRCLE_WORKFLOW_JOB_ID')
        ec2 = boto3.client('ec2')
        if args.action == 'get':
            get(ec2, build_id)
        else:
            destroy(ec2, build_id)
    except (BotoCoreError, ClientError, RuntimeError, ValueError) as error:
        sys.exit(str(error))


if __name__ == '__main__':
    main()
