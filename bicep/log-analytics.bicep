@description('Specifies the name of the log analytics workspace.')
param laName string = 'LawInPlaceUpgrade-${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string

param resourceTags object = {
  Description: 'Resource group for InPlace upgrade'
  Environment: 'Demo'
  ResourceType: 'Monitoring'
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: laName
  location: location  
  tags: resourceTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}
output logAnalyticsName string = logAnalytics.name