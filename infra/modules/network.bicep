// VNet with a web subnet and a db subnet, each protected by its own NSG.
targetScope = 'resourceGroup'

param location string
param tags object

var vnetPrefix = '10.0.0.0/16'
var webPrefix = '10.0.1.0/24'
var dbPrefix = '10.0.2.0/24'

// NSG for the web subnet: allow HTTPS from the internet.
resource webNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-web'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-https-from-internet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

// NSG for the db subnet: only the web subnet may reach port 1433 (SQL).
// Everything else inbound is denied, including other traffic inside the VNet.
resource dbNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-db'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-sql-from-web-subnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: webPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'deny-all-other-inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-learning'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetPrefix]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: webPrefix
          networkSecurityGroup: { id: webNsg.id }
        }
      }
      {
        name: 'snet-db'
        properties: {
          addressPrefix: dbPrefix
          networkSecurityGroup: { id: dbNsg.id }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
