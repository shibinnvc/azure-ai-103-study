// Lab 7 (Week 2, Day 7): the whole week in ONE deployment, built from the modules we already wrote.
// network (VNet, 2 subnets, 2 NSGs) + storage + lifecycle rule + Key Vault + managed identity.
// A few cents at most; delete the group, then purge the vault.
targetScope = 'subscription'

param rgName string = 'rg-learning-lab7'
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

module network 'modules/network.bicep' = {
  name: 'network-${rgName}'
  scope: rg
  params: {
    location: location
    tags: tags
  }
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

// Depends on storage automatically because it uses storage.outputs.
module lifecycle 'modules/lifecycle.bicep' = {
  name: 'lifecycle-${rgName}'
  scope: rg
  params: {
    storageName: storage.outputs.storageName
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault-${rgName}'
  scope: rg
  params: {
    location: location
    tags: tags
    vaultName: 'kv-learn-${uniqueString(rg.id)}'
  }
}

output vnetId string = network.outputs.vnetId
output storageName string = storage.outputs.storageName
output vaultName string = keyvault.outputs.vaultName
output identityName string = keyvault.outputs.identityName
