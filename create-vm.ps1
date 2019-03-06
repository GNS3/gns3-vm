New-VM -Name "GNS3 VM" -Generation 1 -MemoryStartupBytes 1GB -SwitchName "Default Switch"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3_VM-disk1.vhd"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3_VM-disk2.vhd"
