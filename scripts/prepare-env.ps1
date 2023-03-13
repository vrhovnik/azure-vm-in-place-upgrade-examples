param(
    [Parameter(HelpMessage = "Provide the name of the file")]
    $EnvFileToReadFrom = ""
)

if ("" -ne $EnvFileToReadFrom)
{
    #read the env file and set the environment variables    
    Get-Content $EnvFileToReadFrom | ForEach-Object {
        $name, $value = $_.split('=')
        Set-Content env:\$name $value
    }
    Write-Information "Data has been read from the file $EnvFileToReadFrom and environment variables have been set"
}
else
{
    $account = Get-AzContext
    Write-Output "You are logged in to Azure account with subscription name: $($account.Subscription.Name)"
    $env:IPUTenantId=$account.Tenant.Id
    $appId = Read-Host "Enter application ID to have access log ingestion API"

    if ("" -eq $appId)
    {
        Write-Error "Application ID is required"
        exit
    }

    $env:IPUAppId = $appId

    $appSecret = Read-Host "Enter application secret associated with the application ID"
    if ("" -eq $appSecret)
    {
        Write-Error "Application secret is required"
        exit
    }

    $env:IPUAppSecret = $appSecret    
}

# Import the System.Web assembly to be able to use the HttpUtility class
Add-Type -AssemblyName System.Web

Write-Output "Environment variables are set (data below), you can now run the scripts for Azure InPlace upgrade procedures"
Write-Output "----------------------------------------------------------------------------------------------------------------"
Write-Output "Tenant ID: $env:IPUTenantId"
Write-Output "App ID: $env:IPUAppId"
Write-Output "Secret: $env:IPUAppSecret"
Write-Output "----------------------------------------------------------------------------------------------------------------"