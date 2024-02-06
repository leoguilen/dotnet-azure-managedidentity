param location string = resourceGroup().location
param tags object?

param name string
@allowed([
  'Standard'
  'Free'
])
param sku string = 'Free'
param disableLocalAuth bool = true
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
param keyValues AppConfigurationKeyValues[] = []

resource appcs 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    disableLocalAuth: disableLocalAuth
    publicNetworkAccess: publicNetworkAccess
  }
}

resource appcsKv 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = [for item in keyValues: {
  name: item.key
  parent: appcs
  properties: {
    contentType: item.contentType
    value: item.value
    tags: item.tags
  }
}]

output appcsId string = appcs.id
output appcsName string = appcs.name
output appcsEndpoint string = appcs.properties.endpoint

type AppConfigurationKeyValues = {
  key: string
  value: string
  contentType: string
  tags: object?
}
