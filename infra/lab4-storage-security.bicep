// Lab 4 (Week 2, Day 4): storage account + lifecycle rule. SAS tokens are created with the CLI.
// Costs a few cents at most; delete the group when the lab ends.
targetScope = 'subscription'

param rgName string = 'rg-learning-lab4'
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
    storageName: 'stlearn${uniqueString(rg.id)}'
  }
}

module lifecycle 'modules/lifecycle.bicep' = {
  name: 'lifecycle-${rgName}'
  scope: rg
  params: {
    storageName: storage.outputs.storageName
  }
}

output storageName string = storage.outputs.storageName
output containerName string = storage.outputs.containerName
