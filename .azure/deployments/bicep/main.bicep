param location string = resourceGroup().location
param tags object = {
  Project: 'Managed Identity Demo'
  Environment: 'Development'
  Provisioner: 'Bicep'
}

param acrParams object = {
  acrName: 'crdemodev${location}001'
  acrAdminUserEnabled: true
  acrSku: 'Basic'
  location: location
  tags: tags
}

param appcsParams object = {
  name: 'appcs-demo-dev-${location}-001'
  sku: 'Standard'
  disableLocalAuth: false
  publicNetworkAccess: 'Enabled'
  keyValues: [
    {
      key: 'Azure:ServiceBus:Namespace'
      value: 'namespace'
      contentType: 'text/plain'
      tags: {
        Project: 'Managed Identity Demo'
      }
    }
    {
      key: 'Azure:ServiceBus:QueueName'
      value: 'events'
      contentType: 'text/plain'
      tags: {
        Project: 'Managed Identity Demo'
      }
    }
  ]
  location: location
  tags: tags
}

param aciParams object = {
  aciName: 'ci-demo-dev-${location}-001'
  aciSku: 'Standard'
  containerProps: [
    {
      name: 'eventconsumer'
      properties: {
        image: 'crdemodev${location}001.azurecr.io/eventconsumer'
        resources: {
          requests: {
            cpu: 1
            memoryInGB: 1
          }
        }
        ports: [
          {
            port: 80
            protocol: 'TCP'
          }
        ]
      }
    }
  ]
  osType: 'Linux'
  restartPolicy: 'Always'
  ipAddress: {
    type: 'Public'
    ports: [
      {
        port: 80
        protocol: 'TCP'
      }
    ]
  }
  location: location
  tags: tags
}

module acr 'modules/acr.bicep' = {
  name: acrParams.acrName
  params: {
    acrName: acrParams.acrName
    acrAdminUserEnabled: acrParams.acrAdminUserEnabled
    acrSku: acrParams.acrSku
    location: acrParams.location
    tags: acrParams.tags
  }
  scope: resourceGroup()
}

module appcs 'modules/appcs.bicep' = {
  name: appcsParams.name
  params: {
    name: appcsParams.name
    sku: appcsParams.sku
    disableLocalAuth: appcsParams.disableLocalAuth
    publicNetworkAccess: appcsParams.publicNetworkAccess
    keyValues: appcsParams.keyValues
    location: appcsParams.location
    tags: appcsParams.tags
  }
  scope: resourceGroup()
}

module aci 'modules/aci.bicep' = {
  name: aciParams.aciName
  params: {
    aciName: aciParams.aciName
    aciSku: aciParams.aciSku
    containersProps: [
      {
        name: aciParams.containerProps[0].name
        properties: {
          image: aciParams.containerProps[0].properties.image
          resources: aciParams.containerProps[0].properties.resources
          ports: aciParams.containerProps[0].properties.ports
          environmentVariables: [
            {
              name: 'Azure__DefaultCredential__ManagedIdentityResourceId'
              value: '1234'
            }
            {
              name: 'Azure__AppConfiguration__Endpoint'
              value: appcs.outputs.appcsEndpoint
            }
          ]
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: acr.outputs.acrLoginServer
        username: acr.outputs.acrName
      }
    ]
    osType: aciParams.osType
    restartPolicy: aciParams.restartPolicy
    ipAddress: aciParams.ipAddress
    location: aciParams.location
    managedIdentities: {
      systemAssigned: true
    }
    tags: aciParams.tags
  }
  scope: resourceGroup()
  dependsOn: [
    acr
    appcs
  ]
}
