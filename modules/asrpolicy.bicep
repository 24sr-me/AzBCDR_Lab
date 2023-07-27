param policyAssignmentName string
param policyDefinitionID string = '/providers/Microsoft.Authorization/policyDefinitions/ac34a73f-9fa5-4067-9247-a3ecae514468'

param sourceRegion string = resourceGroup().location
param targetRegion string = 'ukwest'
param targetResourceGroupId string
param vaultResourceGroupId string
param vaultId string
param recoveryNetworkId string

resource assignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
    name: policyAssignmentName
    location: targetRegion
    identity: {
        type: 'SystemAssigned'
      }
    properties: {
        policyDefinitionId: policyDefinitionID
        displayName: policyAssignmentName
        parameters: {
            sourceRegion: {
                value: sourceRegion
            }
            targetRegion: {
                value: targetRegion
            }
            targetResourceGroupId: {
                value: targetResourceGroupId
            }
            vaultResourceGroupId: {
                value: vaultResourceGroupId
            }
            vaultId: {
                value: vaultId
            }
            recoveryNetworkId: {
                value: recoveryNetworkId
            }
        }
    }
}


output principleId string = assignment.identity.principalId
output assignmentId string = assignment.id
