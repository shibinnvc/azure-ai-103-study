// Lab 2 (Week 2, Day 2): resource group + VNet + 2 subnets + 2 NSGs. All free resources.
targetScope = 'subscription'

param rgName string = 'rg-learning-lab2'
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

output vnetId string = network.outputs.vnetId
