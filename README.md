# Azure Virtual Machine In-place upgrade examples

An in-place upgrade allows you to go from an older operating system to a newer one while keeping your settings, server roles, and data intact. This repository shows few examples of how to effectively perform the procedure. If you want to deep dive into how the update works on Windows Server OS, check this article [here](https://learn.microsoft.com/en-us/windows-server/get-started/perform-in-place-upgrade).

Before proceeding you need to read this two articles to set the base:
1.	[In-place upgrade](https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade) docs
2.	[Windows Setup API](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options?view=windows-11) options

# Table of contents

<!-- TOC -->
* [Prerequisites](#prerequisites)
* [Official way (managed disks)](#official-way--managed-disks-)
* [ISO with Powershell (via Azure VM Custom Script Extension and either managed Azure SDK or Azure Automation or serverless aka Azure Functions)](#iso-with-powershell--via-azure-vm-custom-script-extension-and-either-managed-azure-sdk-or-azure-automation-or-serverless-aka-azure-functions-)
* [Integration with Azure Monitor to get the logs in one place](#integration-with-azure-monitor-to-get-the-logs-in-one-place)
* [Common errors and solutions](#common-errors-and-solutions)
* [Links for additional information](#links-for-additional-information)
* [Contributing](#contributing)
<!-- TOC -->

## Prerequisites

1. [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
2. [Azure](https://portal.azure.com) Subscription and [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.4.0) module installed
3. [Owner role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) on the subscription

## Official way (managed disks)

To start an in-place upgrade the upgrade media must be attached to the VM as a Managed Disk. The upgrade media disk can be used to upgrade multiple VMs, but it can only be used to upgrade a single VM at a time. To upgrade multiple VMs simultaneously multiple upgrade disks must be created for each simultaneous upgrade.

## ISO with Powershell (via Azure VM Custom Script Extension and either managed Azure SDK or Azure Automation or serverless aka Azure Functions)

https://github.com/azure-samples/azure-samples-net-management/tree/master/samples/compute/manage-virtual-machine-extension

##	Integration with Azure Monitor to get the logs in one place

Azure Monitor enables you to monitor your workloads and add your own data to custom table in Azure Log Analytics. We can send data to REST endpoint or save it to events on the system and onboarding Azure VM to the Azure Monitoring, which will pick up the data in the system events.

https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api?tabs=powershell

## Common errors and solutions

# Links for additional information

1. [In-place upgrade](https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade) docs
2. [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
3. [Run scripts on Azure Virtual Machine with Run command](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command-managed)
4. [Custom script extensions in Azure Virtual Machine](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows)
5. [Create snapshot of the disks](https://learn.microsoft.com/en-us/azure/virtual-machines/snapshot-copy-managed-disk?tabs=portal)
6. [Backup and restore for Managed Disks](https://learn.microsoft.com/en-us/azure/virtual-machines/backup-and-disaster-recovery-for-azure-iaas-disks)
7. [Azure Monitor HTTP Data Collectior API](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api?tabs=powershell)

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
