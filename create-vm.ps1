# Create the GNS3 VM with nested virtualization support
$Manufacturer = (Get-WMIObject win32_Processor).Manufacturer
$WindowsVersion = ([environment]::OSVersion.Version).Major
$BuildNumber = ([environment]::OSVersion.Version).Build
$SwitchName = "Default Switch"
if ($Manufacturer -eq "GenuineIntel") {
  if ($WindowsVersion -eq 10 -and $BuildNumber -lt 14393) {
    Write-Error "Hyper-V with nested virtualization is only supported on Windows 10 Anniversary Update (build 10.0.14393) or later" -ErrorAction Stop
  }
  New-VM -Name "GNS3 VM" -Generation 1 -MemoryStartupBytes 1GB -SwitchName $SwitchName
}
ElseIf ($Manufacturer -eq "AuthenticAMD") {
  if ($WindowsVersion -eq 10 -and $BuildNumber -lt 19640) {
    Write-Error "Windows 10 (build 10.0.19640) or later is required by Hyper-V to support nested virtualization with AMD processors" -ErrorAction Stop
  }
  New-VM -Name "GNS3 VM" -Generation 1 -Version 9.3 -MemoryStartupBytes 1GB -SwitchName $SwitchName
}
Else {
    Write-Error "Hyper-V with nested virtualization does not support $Manufacturer processors" -ErrorAction Stop
}
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3 VM-disk001.vhd"
Add-VMHardDiskDrive -VMName "GNS3 VM" -Path "GNS3 VM-disk002.vhd"
Set-VMProcessor -VMName "GNS3 VM" -ExposeVirtualizationExtensions $true
Set-VMNetworkAdapter -VMName "GNS3 VM" -MacAddressSpoofing On
