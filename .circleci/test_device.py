"""Offline tests for EC2 builder provisioning and cleanup."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import MagicMock, patch

from botocore.exceptions import WaiterError
from botocore.validate import validate_parameters


spec = importlib.util.spec_from_file_location(
    'device', Path(__file__).with_name('device.py'))
device = importlib.util.module_from_spec(spec)
spec.loader.exec_module(device)


class DeviceTests(unittest.TestCase):

    def setUp(self):
        self.environment = patch.dict(os.environ, {
            'EC2_ARCHITECTURE': 'x86_64',
            'EC2_KEY_NAME': 'builder-key',
            'EC2_SUBNET_ID': 'subnet-test',
            'EC2_SECURITY_GROUP_ID': 'sg-test',
        }, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.ec2 = MagicMock()
        self.ec2.describe_instance_types.return_value = {'InstanceTypes': [{
            'BareMetal': True,
            'ProcessorInfo': {'SupportedArchitectures': ['x86_64']},
        }]}
        self.image = {
            'ImageId': 'ami-test',
            'CreationDate': '2026-01-01T00:00:00.000Z',
            'Architecture': 'x86_64',
            'RootDeviceType': 'ebs',
            'RootDeviceName': '/dev/sda1',
            'BlockDeviceMappings': [{
                'DeviceName': '/dev/sda1', 'Ebs': {'VolumeSize': 8},
            }],
        }
        self.ec2.describe_images.return_value = {'Images': [self.image]}
        self.instance = {
            'InstanceId': 'i-test',
            'State': {'Name': 'pending'},
        }
        self.ec2.run_instances.return_value = {'Instances': [self.instance]}
        self.set_instances([])

    def set_instances(self, instances):
        self.ec2.get_paginator.return_value.paginate.return_value = [
            {'Reservations': [{'Instances': instances}]},
        ]

    def test_launch_x86(self):
        self.assertEqual(device.launch_instance(self.ec2, 'job-1'), self.instance)
        request = self.ec2.run_instances.call_args.kwargs
        # Validate against the AWS API model without making any network requests.
        session = device.boto3.session.Session()
        shape = session._session.get_service_model('ec2').operation_model(
            'RunInstances').input_shape
        validate_parameters(request, shape)
        self.assertEqual(request['InstanceType'], 'c5.metal')
        self.assertEqual(request['KeyName'], 'builder-key')
        self.assertEqual(request['MinCount'], 1)
        self.assertEqual(request['MaxCount'], 1)
        self.assertEqual(request['InstanceInitiatedShutdownBehavior'], 'terminate')
        self.assertIn('--on-active=90m', request['UserData'])
        self.assertIn('--unit=gns3-builder-watchdog', request['UserData'])
        self.assertIn(device.HEARTBEAT_FILE, request['UserData'])
        self.assertEqual(request['MetadataOptions']['HttpTokens'], 'required')
        self.assertEqual(request['NetworkInterfaces'], [{
            'DeviceIndex': 0, 'SubnetId': 'subnet-test', 'Groups': ['sg-test'],
            'AssociatePublicIpAddress': True, 'DeleteOnTermination': True,
        }])
        self.assertEqual(request['BlockDeviceMappings'], [{
            'DeviceName': '/dev/sda1',
            'Ebs': {'VolumeSize': 200, 'VolumeType': 'gp3',
                    'DeleteOnTermination': True, 'Encrypted': True},
        }])
        for resource in request['TagSpecifications']:
            self.assertIn({'Key': 'BuildID', 'Value': 'job-1'}, resource['Tags'])

    def test_launch_arm64(self):
        os.environ['EC2_ARCHITECTURE'] = 'arm64'
        self.ec2.describe_instance_types.return_value['InstanceTypes'][0][
            'ProcessorInfo']['SupportedArchitectures'] = ['arm64']
        self.image['Architecture'] = 'arm64'
        device.launch_instance(self.ec2, 'arm-job')
        self.assertEqual(self.ec2.run_instances.call_args.kwargs['InstanceType'], 'c6g.metal')
        filters = self.ec2.describe_images.call_args.kwargs['Filters']
        self.assertIn({'Name': 'architecture', 'Values': ['arm64']}, filters)

    def test_overrides(self):
        os.environ.update({
            'EC2_INSTANCE_TYPE_X86_64': 'm5.metal',
            'EC2_AMI_ID_X86_64': 'ami-custom',
            'EC2_VOLUME_SIZE': '300',
        })
        device.launch_instance(self.ec2, 'job-1')
        self.ec2.describe_images.assert_called_once_with(ImageIds=['ami-custom'])
        request = self.ec2.run_instances.call_args.kwargs
        self.assertEqual(request['InstanceType'], 'm5.metal')
        self.assertEqual(request['BlockDeviceMappings'][0]['Ebs']['VolumeSize'], 300)

    def test_select_latest_canonical_image(self):
        newer = dict(self.image, ImageId='ami-newer', CreationDate='2026-02-01T00:00:00.000Z')
        self.ec2.describe_images.return_value['Images'].append(newer)
        device.launch_instance(self.ec2, 'job-1')
        self.assertEqual(self.ec2.run_instances.call_args.kwargs['ImageId'], 'ami-newer')
        self.assertEqual(self.ec2.describe_images.call_args.kwargs['Owners'], ['099720109477'])

    def test_reject_invalid_launch_configuration(self):
        cases = [
            ({'EC2_ARCHITECTURE': 'invalid'}, 'EC2_ARCHITECTURE'),
            ({'EC2_KEY_NAME': ''}, 'EC2_KEY_NAME'),
            ({'EC2_SUBNET_ID': ''}, 'EC2_SUBNET_ID'),
            ({'EC2_SECURITY_GROUP_ID': ''}, 'EC2_SECURITY_GROUP_ID'),
            ({'EC2_VOLUME_SIZE': '1'}, 'smaller'),
            ({'EC2_VOLUME_SIZE': 'invalid'}, 'invalid literal'),
        ]
        for environment, message in cases:
            with self.subTest(environment=environment), patch.dict(os.environ, environment):
                with self.assertRaisesRegex((RuntimeError, ValueError), message):
                    device.launch_instance(self.ec2, 'job-1')
        self.ec2.run_instances.assert_not_called()

    def test_reject_virtual_instance(self):
        self.ec2.describe_instance_types.return_value['InstanceTypes'][0]['BareMetal'] = False
        with self.assertRaisesRegex(RuntimeError, 'bare metal'):
            device.launch_instance(self.ec2, 'job-1')
        self.ec2.run_instances.assert_not_called()

    def test_reject_wrong_ami_architecture(self):
        self.image['Architecture'] = 'arm64'
        with self.assertRaisesRegex(RuntimeError, 'match EC2_ARCHITECTURE'):
            device.launch_instance(self.ec2, 'job-1')

    def test_no_images(self):
        self.ec2.describe_images.return_value['Images'] = []
        with self.assertRaisesRegex(RuntimeError, 'No Ubuntu'):
            device.launch_instance(self.ec2, 'job-1')

    def test_lookup_is_scoped_and_paginated(self):
        self.ec2.get_paginator.return_value.paginate.return_value = [
            {'Reservations': []},
            {'Reservations': [{'Instances': [self.instance]}]},
        ]
        self.assertEqual(device.find_instances(self.ec2, 'job-1'), [self.instance])
        filters = self.ec2.get_paginator.return_value.paginate.call_args.kwargs['Filters']
        self.assertIn({'Name': 'tag:BuildID', 'Values': ['job-1']}, filters)
        self.assertIn({'Name': 'tag:ManagedBy', 'Values': [device.MANAGED_BY]}, filters)
        self.assertIn({'Name': 'instance-state-name',
                       'Values': ['pending', 'running', 'stopping', 'stopped', 'shutting-down']},
                      filters)

    def test_get_waits_and_prints_only_public_ip(self):
        self.ec2.describe_instances.return_value = {'Reservations': [{
            'Instances': [dict(self.instance, PublicIpAddress='192.0.2.1')],
        }]}
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            device.get(self.ec2, 'job-1')
        self.assertEqual(output.getvalue(), '192.0.2.1\n')
        self.ec2.get_waiter.assert_called_once_with('instance_status_ok')
        self.ec2.get_waiter.return_value.wait.assert_called_once_with(
            InstanceIds=['i-test'], IncludeAllInstances=True,
            WaiterConfig={'Delay': 10, 'MaxAttempts': 120})

    def test_existing_instance_is_reused(self):
        self.set_instances([self.instance])
        self.ec2.describe_instances.return_value = {'Reservations': [{
            'Instances': [dict(self.instance, PublicIpAddress='192.0.2.1')],
        }]}
        with contextlib.redirect_stdout(io.StringIO()):
            device.get(self.ec2, 'job-1')
        self.ec2.run_instances.assert_not_called()

    def test_get_rejects_duplicate_or_inactive_instances(self):
        for instances in [
                [self.instance, self.instance],
                [dict(self.instance, State={'Name': 'stopped'})],
                [dict(self.instance, State={'Name': 'shutting-down'})]]:
            with self.subTest(instances=instances):
                self.set_instances(instances)
                with self.assertRaises(RuntimeError):
                    device.get(self.ec2, 'job-1')
        self.ec2.run_instances.assert_not_called()

    def test_get_fails_on_waiter_timeout(self):
        self.ec2.get_waiter.return_value.wait.side_effect = WaiterError(
            name='instance_status_ok', reason='Max attempts exceeded', last_response={})
        with self.assertRaises(WaiterError):
            device.get(self.ec2, 'job-1')
        self.ec2.describe_instances.assert_not_called()

    def test_get_rejects_missing_public_ip(self):
        self.ec2.describe_instances.return_value = {'Reservations': [{
            'Instances': [self.instance],
        }]}
        with self.assertRaisesRegex(RuntimeError, 'no public IPv4'):
            device.get(self.ec2, 'job-1')

    def test_destroy_terminates_all_job_instances_without_launch_configuration(self):
        os.environ.clear()
        self.set_instances([self.instance, dict(self.instance, InstanceId='i-other')])
        device.destroy(self.ec2, 'job-1')
        self.ec2.terminate_instances.assert_called_once_with(
            InstanceIds=['i-test', 'i-other'])
        self.ec2.get_waiter.assert_not_called()
        self.ec2.describe_images.assert_not_called()

    def test_destroy_skips_shutting_down_instances(self):
        shutting_down = dict(self.instance, InstanceId='i-shutting-down',
                             State={'Name': 'shutting-down'})
        self.set_instances([shutting_down])
        device.destroy(self.ec2, 'job-1')
        self.ec2.terminate_instances.assert_not_called()
        self.ec2.get_waiter.assert_not_called()

    def test_destroy_terminates_active_and_skips_shutting_down(self):
        shutting_down = dict(self.instance, InstanceId='i-shutting-down',
                             State={'Name': 'shutting-down'})
        self.set_instances([self.instance, shutting_down])
        device.destroy(self.ec2, 'job-1')
        self.ec2.terminate_instances.assert_called_once_with(InstanceIds=['i-test'])
        self.ec2.get_waiter.assert_not_called()

    def test_destroy_is_idempotent(self):
        device.destroy(self.ec2, 'job-1')
        self.ec2.terminate_instances.assert_not_called()
        self.ec2.get_waiter.assert_not_called()

    def test_main_requires_job_identity(self):
        with patch.object(sys, 'argv', ['device.py', 'destroy']):
            with self.assertRaisesRegex(SystemExit, 'CIRCLE_WORKFLOW_JOB_ID'):
                device.main()


if __name__ == '__main__':
    unittest.main()
