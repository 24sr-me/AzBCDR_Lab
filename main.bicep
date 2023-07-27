// =========== main.bicep ===========

param prodlocation string = 'uksouth'
param drlocation string = 'ukwest'
param nameID string = utcNow('ddMMyyHHmm')
param rgName string = 'rg-${nameID}'
param rgNameasr string = 'rg-${nameID}-asr'

@description('Username for the Virtual Machine.')
param adminUsername string = 'stu'

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

param policyDefinitionID string = '/providers/Microsoft.Authorization/policyDefinitions/ac34a73f-9fa5-4067-9247-a3ecae514468'

var vms = [
  {
    name: 'vm-${nameID}-1'
    ip: '10.1.0.4'
    drpubip: 'vm-${nameID}-1-drpip'
  }
  {
    name: 'vm-${nameID}-2'
    ip: '10.1.0.5'
    drpubip: 'vm-${nameID}-2-drpip'
  }
]


// Setting target scope
targetScope = 'subscription'

// Creating resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: prodlocation
}

resource rgasr 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgNameasr
  location: drlocation

}

// Deploying vnets using module
module prodvnet './modules/vnet.bicep' =  { 
    name: 'deploy-vnet-${nameID}-prod'
  scope: rg
  params: {
    VNetName:'vnet-${nameID}-prod'
    subnetName: 'default'
    location: prodlocation
    addressPrefix: '10.1.0.0/24'
    subnetPrefix: '10.1.0.0/24'
  }

}

module drvnet './modules/vnet.bicep' =  {
  name: 'deploy-vnet-${nameID}-dr'
scope: rgasr
params: {
  VNetName:'vnet-${nameID}-dr'
  subnetName: 'default'
  location: drlocation
  addressPrefix: '10.2.0.0/24'
  subnetPrefix: '10.2.0.0/24'
}

}
module testvnet './modules/vnet.bicep' =  {
  name: 'deploy-vnet-${nameID}-test'
scope: rgasr
params: {
  VNetName:'vnet-${nameID}-test'
  subnetName: 'default'
  location: drlocation
  addressPrefix: '10.3.0.0/24'
  subnetPrefix: '10.3.0.0/24'
}

}

module peerProdDR './modules/vnetpeer.bicep' = {
  name: 'vnet-peer-prod-dr-${nameID}'
  scope: rg
  params: {
    VirtualNetworkName: 'vnet-${nameID}-prod'
    RemoteVirtualNetworkID: drvnet.outputs.outvnetID
  }
  dependsOn:[
    prodvnet
    drvnet
  ]
}

module peerDRProd './modules/vnetpeer.bicep' = {
  name: 'vnet-peer-dr-prod-${nameID}'
  scope: rgasr
  params: {
    VirtualNetworkName: 'vnet-${nameID}-dr'
    RemoteVirtualNetworkID: prodvnet.outputs.outvnetID
  }
  dependsOn:[
    prodvnet
    drvnet
  ]
}

module backupRSV './modules/rsv.bicep' = {
  name: 'deploy-backup-rsv-${nameID}'
  scope: rg
  params: {
    vaultName: 'rsv-${nameID}-backup'
    location: prodlocation
  }

}

module drRSV './modules/rsv.bicep' = {
  name: 'deploy-dr-rsv-${nameID}'
  scope: rgasr
  params: {
    vaultName: 'rsv-${nameID}-dr'
    location: drlocation
  }

}

module drpol './modules/asrpolicy.bicep' =  {
  name: 'deploy-dr-policy-${nameID}'
  scope: rg
  params: {
    policyAssignmentName: 'Configure ASR for ${nameID}'
    policyDefinitionID: policyDefinitionID
    sourceRegion: rg.location
    targetRegion: rgasr.location
    targetResourceGroupId: rgasr.id
    vaultResourceGroupId: rgasr.id
    vaultId: drRSV.outputs.vaultId
    recoveryNetworkId: drvnet.outputs.outvnetID
  }
  dependsOn: [
    drRSV
    drvnet
  ]
  
}

module sourceRole './modules/asrpolicyroleassignement.bicep' = {
  name: 'role-assignment-${nameID}'
  params: {
      roleAssignmentName: 'role-assignment-${nameID}'
      principalId: drpol.outputs.principleId
  }
  scope: rg
  dependsOn:[
    drpol
  ]
}

module taregtRole './modules/asrpolicyroleassignement.bicep' = {
  name: 'role-assignment-${nameID}-asr'
  params: {
      roleAssignmentName: 'role-assignment-${nameID}-asr'
      principalId: drpol.outputs.principleId
  }
  scope: rgasr
  dependsOn:[
    drpol
  ]
}

module publicips './modules/publicIP.bicep' =  [for i in vms:{
  name: 'deploy-vm-${i.name}-pip'
  scope: rgasr
  params: {
    publicIpName: 'dr-${i.name}_pip'
    dnsName: i.name
  }
  dependsOn: [
    drRSV
  ]
  
}]

// Deploying vm using module
module winvm './modules/bcdr-windows.bicep' =  [for i in vms:{
  name: 'deploy-vm-${i.name}'
  scope: rg 
  params: {
    vmName: i.name
    adminUsername: adminUsername
    adminPassword: adminPassword
    location: prodlocation
    subnetName: 'default'
    virtualNetworkName: prodvnet.outputs.outvnetName
    vaultName: backupRSV.outputs.vaultName
    rsvid: backupRSV.outputs.vaultId
    ip: i.ip
  }
  dependsOn: [
    prodvnet
    backupRSV
    drRSV
    // drpol
  ]
  
}]


module trafficmanager './modules/trafficmanager.bicep' = {
  name: 'deploy-trafficmanager-${nameID}'
  scope: rg
  params: {
    uniqueDnsName: 'trafficmanager-${nameID}'
    name: 'trafficmanager-${nameID}'
    prodlocation: prodlocation
    drlocation: drlocation
    prodep1: winvm[0].outputs.outID
    prodep2: winvm[1].outputs.outID
    drdep1: publicips[0].outputs.outID
    drdep2: publicips[1].outputs.outID


  }
  dependsOn: [
    winvm
    publicips
  ]
  
}
