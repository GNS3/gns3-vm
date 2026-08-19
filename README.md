# FOR DEVELOPMENT ONLY

Go to http://www.gns3.com if you are looking for 
the GNS3 VM. Otherwise GNS3 will not be included in the
VM.

# GNS3 VM

Build a GNS3 Virtual Machine 

* Support Qemu, dynamips, VPCS, IOU and Docker
* It's based on a ubuntu-server LTS 14.04 64 bits
* Support GNS3 update without losing your data
* No need to release a new VM when a new release is out
* By default you can use it in gns3 and access to the internet
* The VM as Nat and HostOnly adapter
* sudo is allowed without password
* Default account: gns3 / gns3
* A graphical interface allow gns3 management
* GNS3 data are installed in /opt on a seperate disk
* An optional eth2 is configured allowing user to add a bridge interface

## Building 

You need to install packer before.

### VirtualBox

Run:
```
./virtualbox.sh
```


This step will build the base VM as an OVA without install gns3 on it.

If you want to install GNS3 you need to unzip the OVA and run:
```
./release_virtualbox.sh 1.4.0 GNS3\ VM.ova
```

### VMware

Run:
```
./vmware.sh
```

For exporting to OVA you need to install:
https://my.vmware.com/web/vmware/details?downloadGroup=OVFTOOL400&productId=353


This step will build the base VM as an OVA without install gns3 on it.

If you want to install GNS3 you need to unzip the OVA and run:
```
./release_vmware.sh 1.4.0 GNS3\ VM.ova
```

#### Upload to ESXi

```
ovftool --allowAllExtraConfig -dm=thin  -ds=datastore1 "GNS3 VM.ova" "vi://root:PASSWORD@HOST"
```

## Tools

### ova.py

Show content of an ova file

### workstation_to_esxi.py

Convert the ova from vmware workstation to esxi

### last_vm_version.py

Get last vm version on Github


### push_config_to_vm.sh

Sync local configuration via SSH to a VM. Use for testing modifications.

