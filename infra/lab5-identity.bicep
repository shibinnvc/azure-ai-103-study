// Lab 5 (Week 2, Day 5): an empty resource group to practise RBAC on. Free.
// Role assignments are done by hand in the portal in this lab (the point is to see them).
targetScope = 'subscription'

param rgName string = 'rg-learning-lab5'
param location string = 'centralindia'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: {
    project: 'learning'
    phase: '2'
    owner: 'shibin'
  }
}

output rgId string = rg.id
