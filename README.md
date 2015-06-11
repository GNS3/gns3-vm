# GNS3 VM

Build a GNS3 Virtual Machine 

* Support Qemu, dynamips, VPCS and IOU
* It's based on a ubuntu-server LTS 14.04 64 bits
* Support GNS3 update without losing your data
* No need to release a new VM when a new release is out
* By default you can use it in gns3 and access to the internet
* The VM as Nat and HostOnly adapter
* sudo is allowed without password
* Default account: gns3 / gns3
* A graphical interface allow gns3 management
* GNS3 data are installed in /opt on a seperate disk

## Building 

You need to install packer before.

### VirtualBox

Run:
```
packer build -only=virtualbox-iso gns3.json
packer build -only=virtualbox-ovf gns3_compress.json
```

Output is located here: *output-virtualbox-ovf/gns3.ova*

### VmWare

Run:
```
packer build -only=vmware-iso gns3.json
packer build -only=vmware-vmx gns3_compress.json
```
