targetScope = 'resourceGroup'

@description('principalId of the user that will be given contributor access to the resourceGroup')
param principalId string

@description('roleDefinition to apply to the resourceGroup - default is contributor')
param roleDefinitionId string = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

@description('Unique name for the roleAssignment in the format of a guid')
param roleAssignmentName string


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleAssignmentName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}
