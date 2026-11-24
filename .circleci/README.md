# CircleCI EC2 builders

The tag-triggered CircleCI jobs provision Ubuntu 24.04 EC2 bare-metal instances:
`c5.metal` for x86_64 and `c6g.metal` for ARM64. Bare metal provides the hardware
virtualization needed by the x86 hypervisors; the ARM64 build retains its existing
QEMU software-emulation configuration. Check regional availability, EC2 quotas,
and pricing before running a build.

Configure these CircleCI project or context environment variables:

| Variable | Purpose |
| --- | --- |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | AWS credentials, or use another standard boto3 credential provider. |
| `AWS_SESSION_TOKEN` | Required when using temporary AWS credentials. |
| `AWS_DEFAULT_REGION` | Region containing the builders and networking resources. |
| `EC2_SUBNET_ID` | Public subnet with an Internet Gateway route and available public IPv4 addresses. |
| `EC2_SECURITY_GROUP_ID` | Security group allowing SSH from the CircleCI executor and outbound build/download traffic. |
| `EC2_KEY_NAME` | Existing EC2 key pair in that region. |
| `EC2_INSTANCE_TYPE_X86_64`, `EC2_INSTANCE_TYPE_ARM64` | Optional bare-metal instance type overrides for each architecture. |
| `EC2_AMI_ID_X86_64`, `EC2_AMI_ID_ARM64` | Optional Ubuntu 24.04 AMI overrides; otherwise the latest matching Canonical AMI is selected. Custom images must support the `ubuntu` user, passwordless sudo, cloud-init, and systemd. |
| `EC2_VOLUME_SIZE` | Optional root EBS volume size in GiB (default: `200`). |

Add the private SSH key matching `EC2_KEY_NAME` to the project's **Additional SSH
Keys** in CircleCI; the setup command loads it with `add_ssh_keys`. AWS credentials
must allow `ec2:DescribeImages`, `ec2:DescribeInstanceTypes`,
`ec2:DescribeInstances`, `ec2:DescribeInstanceStatus`, `ec2:RunInstances`,
`ec2:CreateTags`, and `ec2:TerminateInstances`. RunInstances permissions must cover
the selected AMI, instance, subnet, security group, key pair, network interface,
and volume resources. If using a customer-managed EBS encryption key, also grant
the required KMS permissions.

Instances and encrypted gp3 volumes are tagged with `ManagedBy=gns3-vm-circleci`
and the unique CircleCI job ID, so concurrent jobs do not share or terminate each
other's builders. The jobs collect artifacts over SSH as `ubuntu`, use sudo for
build commands, and always attempt termination during finalization. Root volumes
are deleted on termination. Both x86 ZIP and ARM64 UTM `.tar.xz` release archives
are collected, checksummed, and published. A boot-time systemd timer shuts down
the instance after 90 minutes, with EC2 configured to terminate on shutdown, as
a safeguard against interrupted jobs. This timer depends on successful guest
boot and user-data execution; monitor tagged instances for failed boots or
failed cleanup.

For manual provisioning, install `boto3`, set the variables above, and provide a
unique `EC2_BUILD_ID` and `EC2_ARCHITECTURE` (`x86_64` or `arm64`). Run from the
repository root:

```commandline
python3 .circleci/device.py get
python3 .circleci/device.py destroy
```

Use the same region and build ID for cleanup. `destroy` needs only AWS credentials
and the build ID, so it also works after provisioning fails before returning an IP.
