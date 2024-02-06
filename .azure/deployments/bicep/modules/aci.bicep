param location string = resourceGroup().location
param managedIdentities managedIdentitiesType?
param tags object?

param aciName string
@allowed([
  'Confidential'
  'Dedicated'
  'Standard'
])
param aciSku string = 'Standard'
param containersProps containerProperties[]
param imageRegistryCredentials array = []
@allowed([
  'Linux'
  'Windows'
])
param osType string = 'Linux'
@allowed([
  'Always'
  'OnFailure'
  'Never'
])
param restartPolicy string = 'OnFailure'
param ipAddress object?

var formattedUserAssignedIdentities = reduce(map((managedIdentities.?userAssignedResourceIds ?? []), (id) => { '${id}': {} }), {}, (cur, next) => union(cur, next))

var identity = !empty(managedIdentities) ? {
  type: (managedIdentities.?systemAssigned ?? false) ? (!empty(managedIdentities.?userAssignedResourceIds ?? {}) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(managedIdentities.?userAssignedResourceIds ?? {}) ? 'UserAssigned' : null)
  userAssignedIdentities: !empty(formattedUserAssignedIdentities) ? formattedUserAssignedIdentities : null
} : null

resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  identity: identity
  tags: tags
  properties: {
    sku: aciSku
    containers: [
      for containerProps in containersProps: {
        name: containerProps.name
        properties: containerProps.properties
      }
    ]
    imageRegistryCredentials: imageRegistryCredentials
    osType: osType
    restartPolicy: restartPolicy
    ipAddress: ipAddress
  }
}

output aciId string = aci.id
output aciName string = aci.name

type managedIdentitiesType = {
  systemAssigned: bool?
  userAssignedResourceIds: string[]?
}?

type containerProperties = {
  name: string
  properties: {
    image: string
    resources: {
      requests: {
        cpu: int
        memoryInGB: int
      }
    }
    ports: [
      {
        port: int
        protocol: string
      }
    ]
    environmentVariables: [
      {
        name: string
        value: string
      }
      {
        name: string
        value: string
      }
    ]
  }
}
