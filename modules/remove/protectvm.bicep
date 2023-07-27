var vmName = 'vm-2205230309-1'
var vaultName = 'rsv-2205230309-backup'
var backupFabric = 'Azure'
var backupPolicyName = 'DefaultPolicy'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vmName}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vmName}'
var vmid = '/subscriptions/19fb5289-4b4c-404f-898a-ad75164650dd/resourceGroups/rg-2205230309/providers/Microsoft.Compute/virtualMachines/vm-2205230309-1'
var rsvid = '/subscriptions/19fb5289-4b4c-404f-898a-ad75164650dd/resourceGroups/rg-2205230309/providers/Microsoft.RecoveryServices/vaults/rsv-2205230309-backup'

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName}/${backupFabric}/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: '${rsvid}/backupPolicies/${backupPolicyName}'
    sourceResourceId: vmid
  }
}
