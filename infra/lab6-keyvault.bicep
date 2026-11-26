// Lab 6 (Week 2, Day 6): Key Vault + managed identity. A few cents at most; delete and purge afterwards.
// Role assignments and the container test are done with the CLI so each step is visible.
targetScope = 'subscription'

param rgName string = 'rg-learning-lab6'
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

module kv 'modules/keyvault.bicep' = {
  name: 'kv-${rgName}'
  scope: rg
  params: {
    location: location
    tags: tags
    vaultName: 'kv-learn-${uniqueString(rg.id)}'
  }
}

output vaultName string = kv.outputs.vaultName
output vaultUri string = kv.outputs.vaultUri
output identityName string = kv.outputs.identityName
output identityPrincipalId string = kv.outputs.identityPrincipalId
output identityResourceId string = kv.outputs.identityResourceId
