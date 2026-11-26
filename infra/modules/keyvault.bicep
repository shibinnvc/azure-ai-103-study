// Key Vault (RBAC mode) + a user-assigned managed identity for the app.
targetScope = 'resourceGroup'

param location string
param tags object

@description('Globally unique, 3-24 chars, letters/digits/hyphens.')
param vaultName string
param identityName string = 'id-learning-app'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true // permissions come from Azure RBAC roles, not old access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 7 // shortest allowed; deleted vault name stays reserved this long
    // enablePurgeProtection is left off on purpose: once on it can never be turned off,
    // and it would block cleanup of this lab. Turn it on in production.
  }
}

output vaultName string = vault.name
output vaultUri string = vault.properties.vaultUri
output identityName string = identity.name
output identityPrincipalId string = identity.properties.principalId
output identityResourceId string = identity.id
