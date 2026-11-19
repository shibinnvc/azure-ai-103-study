// Deploys a Delete lock on the resource group this module is scoped to.
targetScope = 'resourceGroup'

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'lock-no-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Learning lab: blocks accidental deletion. Remove before cleanup.'
  }
}
