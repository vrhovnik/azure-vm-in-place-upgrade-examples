# Azure Virtual Machine In-place upgrade examples

An in-place upgrade allows you to go from an older operating system to a newer one while keeping your settings, server
roles, and data intact. This repository shows few examples of how to effectively perform the procedure. If you want to
deep dive into how the update works on Windows Server OS, check this
article [here](https://learn.microsoft.com/en-us/windows-server/get-started/perform-in-place-upgrade).

Before proceeding you need to read this two articles to set the base:

1. [In-place upgrade](https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade) docs
2. [Windows Setup API](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options?view=windows-11)
   options

# Table of contents

<!-- TOC -->
* [Azure Virtual Machine In-place upgrade examples](#azure-virtual-machine-in-place-upgrade-examples)
* [Table of contents](#table-of-contents)
  * [Prerequisites](#prerequisites)
  * [Official way (managed disks)](#official-way--managed-disks-)
  * [ISO with Powershell (via Azure VM Custom Script Extension and either managed Azure SDK or Azure Automation or serverless aka Azure Functions)](#iso-with-powershell--via-azure-vm-custom-script-extension-and-either-managed-azure-sdk-or-azure-automation-or-serverless-aka-azure-functions-)
  * [Integration with Azure Monitor to get the logs in one place](#integration-with-azure-monitor-to-get-the-logs-in-one-place)
* [Links for additional information](#links-for-additional-information)
* [Contributing](#contributing)
<!-- TOC -->

## Prerequisites

1. [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
2. [Azure](https://portal.azure.com) Subscription
   and [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.4.0) module
   installed
3. [Owner role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) on the
   subscription

To set up the environment you need to create a resource group and a VM with the OS you want to upgrade. You can use
the [Azure Portal](https://portal.azure.com)
or [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/overview?view=azps-9.4.0) to create the VM.

To help with the setup and install tools, go to [script](./scripts) folder:

1. [Init.ps1](./scripts/Init.ps1) - creates a resource group and a VM with the OS you want to upgrade -
   check [bicep](./bicep) folder for parameter files and configure parameters to be used or change the values in script
2. (optional)[Install-Bicep.ps](./scripts/Install-Bicep.ps1) - installs Bicep for ARM template deployment

In order to change the SKU of the machine to upgrade, you can find the values via the Azure Portal or via the
PowerShell. More [here](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage).

```powershell
# GET available SKU in West Europe
$locName = "WestEurope"
Get-AzVMImagePublisher -Location $locName | Select PublisherName

$pubName = "MicrosoftWindowsServer"
Get-AzVMImageOffer -Location $locName -PublisherName $pubName | Select Offer

$offerName = "WindowsServer"
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select Skus
```

## Official way (managed disks)

To start an in-place upgrade the upgrade media must be attached to the VM as a Managed Disk. The upgrade media disk can
be used to upgrade multiple VMs, but it can only be used to upgrade a single VM at a time. To upgrade multiple VMs
simultaneously multiple upgrade disks must be created for each simultaneous upgrade.

To attach the disk to the machine, you can use the following script (you need to go to the [script](./scripts) folder):

```powershell
Create-UpgradableDisk.ps1 -ResourceGroup="InPlaceUpgradeRG" -VmName="ipu-vm-2016" -Location="westeurope" -DiskName="ipu-upgrade-disk" -Zone="" -UpgradeToWindowsServer2019
```

Parameters:

1. **ResourceGroup** - Provide the name of the resourceGroup
2. **VmName** - Provide the name of the VM to be upgraded
3. **Location** - Provide the location of the Azure Resource Group
4. **DiskName** - Provide the name of the disk
5. **Zone** - Provide the name of zone for the source VM
6. **UpgradeToWindowsServer2019** - Provide the name of the OS to upgrade to - you can choose between 2022 or 2019

To start the upgrade, you need to have VM in running state.

1. Connect to the VM using RDP or RDP-Bastion.
2. Determine the drive letter for the upgrade disk (typically E: or F: if there are no other data disks).
3. Start Windows PowerShell.
4. Change directory to the only directory on the upgrade disk.
5. Execute the following command to start the upgrade:

```powershell
.\setup.exe /auto upgrade /dynamicupdate disable
Select the correct "Upgrade to" image based on the current version and configuration of the VM
```

| Upgrade from                             | Upgrade to                                                                             |
|------------------------------------------|----------------------------------------------------------------------------------------|
| Windows Server 2012 R2 (Core)            | Windows Server 2019                                                                    |
| Windows Server 2012 R2                   | Windows Server 2019 (Desktop Experience)                                               |
| Windows Server 2016 (Core)	              | Windows Server 2019 -or- Windows Server 2022                                           |
| Windows Server 2016 (Desktop Experience) | Windows Server 2019 (Desktop Experience) -or- Windows Server 2022 (Desktop Experience) |
| Windows Server 2019 (Core)               | Windows Server 2022                                                                    |
| Windows Server 2019 (Desktop Experience) | Windows Server 2022 (Desktop Experience)                                               |

You will need to upgrade VM to volume license (KMS server activation). Checks docs [for more](https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade#upgrade-vm-to-volume-license-kms-server-activation).

## ISO with Powershell (via Azure VM Custom Script Extension and either managed Azure SDK or Azure Automation or serverless aka Azure Functions)

To start an in-place upgrade you can upgrade via ISO file if ISO file enables the upgrade (check [docs](https://learn.microsoft.com/en-us/windows-server/get-started/perform-in-place-upgrade)).

Code is written in [.NET Core](https://dot.net). You will need to have .NET installed to continue. How to do that is documented [here](https://dotnet.microsoft.com/en-us/download).

Navigate to src folder and to the project folder:

```powershell
Set-Location "./src/UpdateViaManagedAPI"
```

Run the project by executing the following command:

```powershell
dotnet run
```

Follow the instructions on the screen.

If you want to enable additional features, you can read about it more on this site:

```powershell
Start-Process "https://github.com/azure-samples/azure-samples-net-management/tree/master/samples/compute/manage-virtual-machine-extension"
```

_Remarks:_
If you don't want to install .NET SDK on your machine, you can use [GitHub Codespaces](https://github.com/features/codespaces) to run the code. Check this [video](https://www.youtube.com/watch?v=1Vg7bNjJY-0)

## Integration with Azure Monitor to get the logs in one place

Azure Monitor enables you to monitor your workloads and add your own data to custom table in Azure Log Analytics. We can
send data to REST endpoint or save it to events on the system and onboarding Azure VM to the Azure Monitoring, which
will pick up the data in the system events.

Check out great article how to do that [here](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/data-sources-custom-logs).

```powershell
Start-Process "https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api?tabs=powershell"
```

# Links for additional information

1. [In-place upgrade](https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade) docs
2. [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
3. [Run scripts on Azure Virtual Machine with Run command](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command-managed)
4. [Custom script extensions in Azure Virtual Machine](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows)
5. [Create snapshot of the disks](https://learn.microsoft.com/en-us/azure/virtual-machines/snapshot-copy-managed-disk?tabs=portal)
6. [Backup and restore for Managed Disks](https://learn.microsoft.com/en-us/azure/virtual-machines/backup-and-disaster-recovery-for-azure-iaas-disks)
7. [Azure Monitor HTTP Data Collector API](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api?tabs=powershell)

# Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
