# Create the GNS3 VM with nested virtualization support
New-VM -Name "GNS3 VM" -Generation 1 -MemoryStartupBytes 1GB -SwitchName "Default Switch"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3 VM-disk001.vhd"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3 VM-disk002.vhd"
Set-VMProcessor -VMName "GNS3 VM" -ExposeVirtualizationExtensions $true
Set-VMNetworkAdapter -VMName "GNS3 VM" -MacAddressSpoofing On
