# FOR DEVELOPMENT ONLY

The GNS3 VM is a virtual machine that runs the GNS3 server and allows you to run network simulations with GNS3.
GNS3 VMs are released on GitHub (https://github.com/GNS3/gns3-gui/releases) and can be downloaded from the GNS3 website (https://www.gns3.com/software).

# GNS3 VM

GNS3 Virtual Machine (GNS3 VM) features:

* Includes dependencies like uBridge, Qemu, Dynamips, VPCS and Docker.
* Based on the latest Linux Ubuntu LTS.
* Menu to configure the GNS3 VM.
* Optimizations for better performance.
* Support GNS3 updates.
* The VM has NAT and HostOnly adapter.
* Default account: gns3 / gns3.
* GNS3 data is stored in `/opt` on a separate disk.
* mDNS is enabled to allow to discover the GNS3 VM on the network (gns3vm.local).
* NTP is enabled to synchronize the time with Internet time servers.
* SNMP is installed but not enabled by default.
* XRd (containerized IOS XR) support.

# Supported platforms

* Hyper-V, to run GNS3 on Windows using the Hyper-V hypervisor.
* VMware Workstation, to run GNS3 on Windows and Linux using the VMware Workstation hypervisor.
* VMware ESXi, to run GNS3 on a VMware ESXi server.
* VirtualBox, to run GNS3 on Windows, Linux, and macOS using the VirtualBox hypervisor.
* KVM (x86_64 only), to run GNS3 on Linux using the KVM hypervisor.
* UTM (ARM64 only), to run GNS3 on macOS (Apple Silicon) using the UTM hypervisor (https://mac.getutm.app/).

## Building 

Building is only supported on Linux.

Packer needs to be installed on your system. You can download it from https://www.packer.io/downloads.

Plugins for VirtualBox, VMware, and QEMU need to be installed. You can install them with the following commands:

```commandline
packer plugins install github.com/hashicorp/virtualbox
packer plugins install github.com/hashicorp/vmware
packer plugins install github.com/hashicorp/qemu
```

Qemu needs to be installed on your system. You can install it with the following command:

```commandline
apt install -y genisoimage qemu-utils qemu-system-x86 qemu-kvm qemu-system-aarch64
```

## Base VM

A base VM is built with Packer and can be used to build the GNS3 VM for different hypervisors.

Run this script to build the x86_64 base VM:
```
./build_base_vm.sh
```

Run this script to build the ARM64 base VM:
```
./build_base_vm.sh
```

### VMware Workstation

Run:
```
./release_vmware.sh ${GNS3_VERSION} GNS3VM.Base.$(cat version).zip
```

### VirtualBox

The VirtualBox release script uses the VMware VM as a base for creating the VirtualBox VM.

Run:
```
./release_virtualbox.sh ${GNS3_VERSION} GNS3.VM.VMware.Workstation.${GNS3_NUMBER}.zip
```

### Hyper-V

```
./release_hyperv.sh ${GNS3_VERSION} GNS3VM.Base.$(cat version).zip
```

### KVM

The KVM release script requires the VirtualBox zip file to be copied to /tmp before running the script. This is because the KVM release script uses the VirtualBox VM file as a base for creating the KVM VM.

```
cp GNS3.VM.VirtualBox.${GNS3_NUMBER}.zip /tmp/GNS3VM.VirtualBox.${GNS3_NUMBER}.zip
./release_kvm.sh ${GNS3_VERSION}
```

### VMware ESXi

The VMware ESXi release script requires the VMware zip file to be copied to /tmp before running the script. This is because the ESXi release script uses the VMware Workstation VM file as a base for creating the ESXi VM.

```
cp GNS3.VM.VMware.Workstation.${GNS3_NUMBER}.zip /tmp/GNS3VM.VMware.${GNS3_NUMBER}.zip
./release_esxi.sh ${GNS3_VERSION}
```

### UTM (macOS Apple Silicon)

```
./release_qemu_arm64.sh ${GNS3_VERSION} GNS3VM.Base.ARM64.$(cat version).zip
```
