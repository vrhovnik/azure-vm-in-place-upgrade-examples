@description('Name of the Azure Active Directory App Registration')
param appName string = 'app-inplace-upgrade'

@description('Display name in Azure Active Directory')
param displayAppName string = 'Azure InPlace upgrade App'

param resourceTags object = {
   Description: 'Resource group for InPlace upgrade'
    Environment: 'Demo'
    ResourceType: 'Azure Ad App'
}

resource aadAppRegistration 'Microsoft.AzureActiveDirectory/applicationRegistrations@2020-07-01-preview' = {
    name:appName
    tags:resourceTags
    properties:{
        displayName:displayAppName
        identifierUris:['https://localhost']
        replyUrls:['https://localhost/callback']
    }
}

output azureAdAppId string = aadAppRegistration.properties.applicationId
