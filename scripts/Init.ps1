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
$groupNameReturnValue = New-AzSubscriptionDeployment -Location $Location -TemplateFile "bicep\rg.bicep" -TemplateParameterFile "bicep\rg.parameters.json" | ConvertFrom-Json | Select-Object properties
Write-Information $groupNameReturnValue
$groupName = $groupNameReturnValue.properties.outputs.rgName.value
Write-Output "$groupName resource group created."

#deploy log analytics file if not already deployed
$logAnalyticsNameReturnValue = New-AzResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile "bicep\log-analytics.bicep" -TemplateParameterFile "bicep\log-analytics.parameters.json" | ConvertFrom-Json | Select-Object properties
Write-Information $logAnalyticsNameReturnValue
$logAnalyticsName = $logAnalyticsNameReturnValue.properties.outputs.logAnalyticsName.value
Write-Output "Log analytics workspace $logAnalyticsName created."

if ($UseEnvFile)
{
    Get-Content $EnvFileToReadFrom | ForEach-Object {
        $name, $value = $_.split('=')
        Set-Variable -Name $name -Value $value
        Write-Information "Setting $name to $value"
    }    
}
else
{
    #deploy VM if not already deployed with parameters 
    $vmName = Read-Host "Enter VM name"    
    $windowsAdminUsername = Read-Host "Enter username for Windows VM"
    $windowsAdminPassword = Read-Host "Enter password for Windows VM" -AsSecureString
    $publicIpAddressName = Read-Host "Enter public IP address name to be able to RDP into VM"    
}

Write-Output "VM name is $vmName"
Write-Output "Windows username to authenticate $windowsAdminUsername"
Write-Output "Public IP address name: $publicIpAddressName"
# deploy resource group
New-AzResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile "bicep\vm.bicep" -logAnalyticsWorkspace $logAnalyticsName -vmName $vmName -windowsAdminPassword $windowsAdminPassword -publicIpAddressName $publicIpAddressName -windowsAdminUsername $windowsAdminUsername
Write-Information "Creating resources in $groupName resource group."
#deploy app registration if not already deployed
$appRegistrationReturnValue = New-AzSubscriptionDeployment -Location $Location -TemplateFile "bicep\app-registration.bicep" -TemplateParameterFile "bicep\app-registration.parameters.json" | ConvertFrom-Json | Select-Object properties
Write-Information "Azure AD App Registration $appRegistrationReturnValue"
$azureADApp = $appRegistrationReturnValue.properties.outputs.azureAdAppId.value
Write-Output "Azure Ad App Id: $azureADApp"
Write-Output "Resources are created. Check Azure portal for details."
Start-Process "https://portal.azure.com"

Stop-Transcript

# open file for viewing
Start-Process notepad.exe -ArgumentList "$HOME/Downloads/bootstrapper.log"