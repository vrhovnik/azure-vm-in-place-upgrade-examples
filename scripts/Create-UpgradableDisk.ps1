<# 
# SYNOPSIS
# creates disk for upgrade to Windows Server 2022 to be used in Azure InPlace upgrade procedures
#
# DESCRIPTION
# creates disk from private gallery and uses it for upgrade to Windows Server 2022 and attaches it to the VM
#
# NOTES
# Author      : Bojan Vrhovnik
# GitHub      : https://github.com/vrhovnik
# Version 1.0.0
# SHORT CHANGE DESCRIPTION: adding parameters to be used in Azure InPlace upgrade procedures
#>
param(
    [Parameter(HelpMessage = "Provide the name of the resourceGroup")]
    $ResourceGroup="InPlaceUpgradeRG",
    [Parameter(HelpMessage = "Provide the name of the VM to be upgraded")]
    $VmName="ipu-vm-2016",
    [Parameter(HelpMessage = "Provide the location of the resourceGroup")]
    $Location="westeurope",
    [Parameter(HelpMessage = "Provide the name of the disk")]
    $DiskName="ipu-upgrade-disk",
    [Parameter(HelpMessage = "Provide the name of zone for the source VM")]
    $Zone="",
    [Parameter(Mandatory = $false, HelpMessage = "Upgrade to Windows Server 2022 or 2019")]
    [switch]$UpgradeToWindowsServer2019
)

Start-Transcript -Path "$HOME/Downloads/AddingDisk.log" -Force
# Target version for the upgrade - must be either server2022Upgrade or server2019Upgrade
$sku = "server2022Upgrade"
if ($UpgradeToWindowsServer2019)
{
    $sku = "server2019Upgrade"
}

# Common parameters
$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServerUpgrade"
$managedDiskSKU = "Standard_LRS"

Write-Output "Publisher: $publisher, Offer: $offer, Sku: $sku, ResourceGroup: $ResourceGroup, Location: $Location"

# Get the latest version of the special (hidden) VM Image from the Azure Marketplace
$versions = Get-AzVMImage -PublisherName $publisher -Location $Location -Offer $offer -Skus $sku | Sort-Object -Descending { [version]$_.Version }
$latestString = $versions[0].Version

# Get the special (hidden) VM Image from the Azure Marketplace by version - the image is used to create a disk to upgrade to the new version
$image = Get-AzVMImage -Location $Location -PublisherName $publisher -Offer $offer -Skus $sku -Version $latestString

# Create Managed Disk from LUN 0 of the special (hidden) VM Image
$diskConfig = New-AzDiskConfig -SkuName $managedDiskSKU -CreateOption "FromImage" -Location $Location
if ($Zone)
{
    $diskConfig = New-AzDiskConfig -SkuName $managedDiskSKU -CreateOption "FromImage" -Zone $zone -Location $Location
}

$galleryVmId=$image.Id
Write-Output "Creating disk $DiskName from image $galleryVmId"
$diskConfig = Set-AzDiskImageReference -Disk $diskConfig -Id $galleryVmId -Lun 0
$dataDisk1 = New-AzDisk -ResourceGroupName $ResourceGroup -DiskName $DiskName -Disk $diskConfig

Write-Output "Disk created, adding to VM $VmName"
# Get the VM object
$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName
Write-Information "VM object: $vm"

# Add a new data disk configuration
Write-Information "Adding disk to VM $VmName"
$diskAdded = Add-AzVMDataDisk -VM $vm -Name $DiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
Write-Information "Disk added to VM: $diskAdded"

# Update the VM with the new configuration
Update-AzVM -ResourceGroupName $ResourceGroup-VM $VmName

# start VM
Start-AzVM -ResourceGroupName $ResourceGroup -Name $VmName
Write-Output "Disk added to VM $VmName. Get updated version of the VM object to see the changes."

Write-Output "Loop through disks in VM $VmName"
$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName
$vm.StorageProfile.DataDisks | Select-Object Name, Lun, DiskSizeGB

Write-Output "Connect to Azure VM and execute script to upgrade the procedure."
Stop-Transcript