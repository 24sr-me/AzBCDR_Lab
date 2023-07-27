@description('Name of the Vault')
param vaultName string

@description('Change Vault Storage Type (Works if vault has not registered any backup instance)')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
])
param vaultStorageType string = 'GeoRedundant'

@description('Location for all resources.')
param location string

var skuName = 'RS0'
var skuTier = 'Standard'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
  name: vaultName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }

  resource vaultName_vaultstorageconfig 'backupstorageconfig' = {
    name: 'vaultstorageconfig'
    properties: {
      storageModelType: vaultStorageType
      crossRegionRestoreFlag: false
    }
  
  }
  
  resource vaultName_vaultconfig 'backupconfig' = {
    name: 'vaultconfig'
  
    properties: {
      softDeleteFeatureState: 'Disabled'
    }
  }
  properties: {}
}



output vaultName string = recoveryServicesVault.name
output vaultId string = recoveryServicesVault.id
