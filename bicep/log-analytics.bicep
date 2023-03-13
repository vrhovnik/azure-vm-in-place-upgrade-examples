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
var primaryKey = listKeys(logAnalytics.id, logAnalytics.apiVersion).primarySharedKey
output logAnalyticsId string = logAnalytics.id
output logAnalyticsName string = logAnalytics.name
output logAnalyticsKey string = primaryKey