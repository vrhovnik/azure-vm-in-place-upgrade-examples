<# 
# SYNOPSIS
# This script sends logs to Log Analytics via the data collection
#
# DESCRIPTION
# This script sends logs to Log Analytics via the data collection
# More info at: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal 
# LogGenerator.ps1
#   -Log <String>              - Log file to be forwarded
#   [-Table]                   - The name of the custom log table, including "_CL" suffix
## Example
# .\LogGenerator.ps1 -Log "sample_access.json" -Table "Upgrade_CL"
# NOTES
# Author      : Bojan Vrhovnik
# GitHub      : https://github.com/vrhovnik
# Version 1.2.0
# SHORT CHANGE DESCRIPTION: adding app registration and env
#>
################
##### Description: This script sends logs to Log Analytics via the data collection 
##### More info at: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal
################
################
##### Usage
################
# LogGenerator.ps1
#   -Log <String>              - Log file to be forwarded
#   [-Table]                   - The name of the custom log table, including "_CL" suffix
## Example
# .\LogGenerator.ps1 -Log "../sample-data/sample_access.json" -Table "InPlaceUpgrade_CL"
param (
    [Parameter(HelpMessage = "Log file to be forwarded")] 
    [ValidateNotNullOrEmpty()]
    [string]$Log,     
    [Parameter(HelpMessage = "The name of the custom log table, including '_CL' suffix")]
    [ValidateNotNullOrEmpty()]
    [string]$Table
)
# Information needed to authenticate to Azure Active Directory and obtain a bearer token
$tenantId = $env:IPUTenantId
$appId = $env:IPUAppId
$appSecret = $env:IPUAppSecret
#information to send data to the data collection endpoint
$DcrImmutableId = $env:DataCollectionId
$DceURI = $env:DataCollectionUrl
## Obtain a bearer token used to authenticate against the data collection endpoint
## you will need to add type System.Web to use 
# Add-Type -AssemblyName System.Web
$scope = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
$body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
$headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
Write-Information "Token is $bearerToken"

# read json and send to Log Analytics
$body = Get-Content $Log
Write-Output $body

$headers = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json" };
$uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/Custom-$Table" + "?api-version=2021-11-01-preview";
Write-Output "$uri to be called with $body"

$uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers;

Write-Information "Uploaded response is $uploadResponse"   
Write-Output "Writing logs from $Log has finished!"