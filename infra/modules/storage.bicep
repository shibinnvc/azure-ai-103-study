// Storage account with one private blob container and secure defaults.
targetScope = 'resourceGroup'

param location string
param tags object

@description('Globally unique, 3-24 chars, lowercase letters and digits only.')
param storageName string

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS' // 3 copies in one datacenter; cheapest. Use ZRS/GRS for more resilience.
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false // no anonymous access to any container
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'documents'
  properties: {
    publicAccess: 'None'
  }
}

output storageName string = storage.name
output containerName string = container.name
