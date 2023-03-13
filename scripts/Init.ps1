<# 
# SYNOPSIS
# init file and installs all neccessary services to be installed in Azure for Azure InPlace options
#
# DESCRIPTION
# installs all neccessary services to be installed in Azure
#  RESOURCE GROUP
#  Log Analytics
#  Virtual Machine with version of Windows Server 2016 or 2012 or 2019 
#  Public IP address
#
# NOTES
# Author      : Bojan Vrhovnik
# GitHub      : https://github.com/vrhovnik
# Version 1.2.0
# SHORT CHANGE DESCRIPTION: adding environment files and azure app registration
#>
param(
    [Parameter(HelpMessage = "Provide the location")]
    $Location = "WestEurope",
    [Parameter(Mandatory=$false)]
    [switch]$UseEnvFile,
    [Parameter(Mandatory=$false)]
    [switch]$InstallModules,
    [Parameter(Mandatory=$false)]
    [switch]$InstallBicep
)

Start-Transcript -Path "$HOME/Downloads/bootstrapper.log" -Force

# Write-Output "Sign in to Azure account." 
# login to Azure account
# Connect-AzAccount
$subscriptionName = Get-AzContext | Select-Object -ExpandProperty Name
Write-Output "You are logged in to Azure account with subscription name: $subscriptionName"

if ($InstallModules)
{
    Write-Output "Install Az module and register providers."
    #install Az module
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    Install-Module -Name Az.App

    #register providers
    Register-AzResourceProvider -ProviderNamespace Microsoft.App
    # add support for log analytics
    Register-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights
    Write-Output "Modules installed and registered, continuing to Azure deployment nad if selected, Bicep install."
}

if ($InstallBicep) {
    # install bicep
    Write-Output "Installing Bicep."
    # & Install-Bicep.ps1
    Start-Process powershell.exe -FilePath Install-Bicep.ps1 -NoNewWindow -Wait
    Write-Output "Bicep installed, continuing to Azure deployment."
}

Write-Output "Using location $Location data center"

# create resource group if it doesn't exist with bicep file stored in bicep folder
$groupNameReturnValue = New-AzSubscriptionDeployment -Location $Location -TemplateFile "bicep\rg.bicep" | ConvertFrom-Json | Select-Object properties
Write-Information $groupNameReturnValue
$groupName = $groupNameReturnValue.properties.outputs.rgName.value
Write-Information $groupName
#deploy log analytics file if not already deployed
$logAnalyticsNameReturnValue = New-AzResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile "bicep\log-analytics.bicep" -TemplateParameterFile "bicep\log-analytics.parameters.json" | ConvertFrom-Json | Select-Object properties
Write-Information $logAnalyticsNameReturnValue
$logAnalyticsName = $logAnalyticsNameReturnValue.properties.outputs.logAnalyticsName.value

#deploy VM if not already deployed with parameters
Write-Information "Log analytics name is $logAnalyticsName"
$vmName = Read-Host "Enter VM name"
Write-Information "VM name is $vmName"
$windowsAdminUsername = Read-Host "Enter username for Windows VM"
Write-Information "Windows username to authenticate $windowsAdminUsername"
$windowsAdminPassword = Read-Host "Enter password for Windows VM" -AsSecureString
$publicIpAddressName = Read-Host "Enter public IP address name to be able to RDP into VM"
Write-Information "Public IP address name: $publicIpAddressName"
New-AzResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile "bicep\vm.bicep" -logAnalyticsWorkspace $logAnalyticsName -vmName $vmName -windowsAdminPassword $windowsAdminPassword -publicIpAddressName $publicIpAddressName -windowsAdminUsername $windowsAdminUsername    

#deploy app registration if not already deployed


Stop-Transcript

# open file for viewing
Start-Process notepad.exe -ArgumentList "$HOME/Downloads/bootstrapper.log"