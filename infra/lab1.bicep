// Lab 1: resource group + tags (+ optional delete lock), as code.
// Scope is the subscription because a resource group is created at subscription level.
targetScope = 'subscription'

@description('Name of the resource group to create.')
param rgName string = 'rg-learning-lab1'

@description('Azure region. We chose Central India for Weeks 1-3.')
param location string = 'centralindia'

@description('Set to true to also add a Delete lock on the group.')
param enableLock bool = false

var tags = {
  project: 'learning'
  phase: '1'
  owner: 'shibin'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

// The lock lives INSIDE the group, so it is deployed as a module scoped to the group.
module lock 'modules/lock.bicep' = if (enableLock) {
  name: 'lock-${rgName}'
  scope: rg
}

output resourceGroupId string = rg.id
output lockEnabled bool = enableLock
