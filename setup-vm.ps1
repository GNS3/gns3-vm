# Parameters
$VMName = "GNS3 VM"
$VMDisk1 = "gns3vm-disk1.vhdx"
$VMDisk2 = "gns3vm-disk2.vhdx"
$SwitchName = "Default Switch"

# Checks the processor manufacturer and Windows version to ensure compatibility with nested virtualization.
$Manufacturer = (Get-WMIObject win32_Processor).Manufacturer
$WindowsVersion = ([environment]::OSVersion.Version).Major
$BuildNumber = ([environment]::OSVersion.Version).Build
if ($Manufacturer -eq "GenuineIntel") {
  if ($WindowsVersion -eq 10 -and $BuildNumber -lt 14393) {
    Write-Error "Hyper-V with nested virtualization is only supported on Windows 10 Anniversary Update (build 10.0.14393) or later" -ErrorAction Stop
  }
  New-VM -Name $VMName -Generation 2 -MemoryStartupBytes 2GB -SwitchName $SwitchName
}
ElseIf ($Manufacturer -eq "AuthenticAMD") {
  if ($WindowsVersion -eq 10 -and $BuildNumber -lt 19640) {
    Write-Error "Windows 10 (build 10.0.19640) or later is required by Hyper-V to support nested virtualization with AMD processors" -ErrorAction Stop
  }
  New-VM -Name $VMName -Generation 2 -Version 9.3 -MemoryStartupBytes 2GB -SwitchName $SwitchName
}
Else {
    Write-Error "Hyper-V with nested virtualization does not support $Manufacturer processors" -ErrorAction Stop
}
Set-Location $PSScriptRoot

# Set the disks
Add-VMHardDiskDrive -VMName $VMName -Path $VMDisk1
Add-VMHardDiskDrive -VMName $VMName -Path $VMDisk2

# Set the memory and network adapter settings
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true
Set-VMNetworkAdapter -VMName $VMName -MacAddressSpoofing On

# Set the processor count and enable nested virtualization
Set-VMProcessor -VMName $VMName -Count 2
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true

# Enable Secure Boot with the Microsoft UEFI Certificate Authority template
Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

# Set the boot order
$hdd = Get-VMHardDiskDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -BootOrder $hdd
