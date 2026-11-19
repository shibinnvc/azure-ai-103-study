// Lab 3 (Week 2, Day 3): resource group + a storage account with a private container.
// This one costs a few cents at most; delete the group when the lab ends.
targetScope = 'subscription'

param rgName string = 'rg-learning-lab3'
param location string = 'centralindia'

var tags = {
  project: 'learning'
  phase: '2'
  owner: 'shibin'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

module storage 'modules/storage.bicep' = {
  name: 'storage-${rgName}'
  scope: rg
  params: {
    location: location
    tags: tags
    // uniqueString gives a stable 13-char hash of the group id, so the name is unique but repeatable.
    storageName: 'stlearn${uniqueString(rg.id)}'
  }
}

output storageName string = storage.outputs.storageName
output containerName string = storage.outputs.containerName
