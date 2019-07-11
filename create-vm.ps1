# Create vSwitch with NAT support
New-VMSwitch -SwitchName “GNS3VMSwitch” -SwitchType Internal
New-NetIPAddress -IPAddress 172.16.1.254 -PrefixLength 24 -InterfaceAlias “vEthernet (GNS3VMSwitch)”
New-NetNAT -Name “GNS3VMNATNetwork” -InternalIPInterfaceAddressPrefix 172.16.1.0/24

# Create the GNS3 VM with nested virtualization support
New-VM -Name "GNS3 VM" -Generation 1 -MemoryStartupBytes 1GB -SwitchName "GNS3VMSwitch"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3 VM-disk001.vhd"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3 VM-disk002.vhd"
Set-VMProcessor -VMName "GNS3 VM" -ExposeVirtualizationExtensions $true
Set-VMNetworkAdapter -VMName "GNS3 VM" -MacAddressSpoofing On

# Assign a static IP address (not used at the moment)
# Can be read from the guest with: cat /var/lib/hyperv/.kvp_pool_0 | sed 's/\x0//g' | sed 's/IpAddress//g'
#$VmMgmt = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService
#$vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter {ElementName = 'GNS3 VM'}
#$kvpDataItem = ([WMIClass][String]::Format("\\{0}\{1}:{2}", $VmMgmt.ClassPath.Server, $VmMgmt.ClassPath.NamespacePath, "Msvm_KvpExchangeDataItem")).CreateInstance()
#$kvpDataItem.Name = "IpAddress"
#$kvpDataItem.Data = "172.16.1.1"
#$kvpDataItem.Source = 0
#$VmMgmt.AddKvpItems($Vm, $kvpDataItem.PSBase.GetText(1))
