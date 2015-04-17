# Packer

Build a GNS3 appliance

* Support Qemu, dynamips, VPCS and IOU
* It's based on a ubuntu-server LTS 14.04 64 bits
* Support GNS3 update without losing your data
* No need to release a new VM when a new release is out
* By default you can use it in gns3 and access to the internet
* The VM as Nat, HostOnly and Bridge adapter
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
packer build gns3_compress.json
```

Output is located here: *output-virtualbox-ovf/gns3.ova*

### VmWare

Run:
```
packer build -only=vmare-iso gns3.json
```
