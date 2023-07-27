param location string = resourceGroup().location
param VNetName string
param addressPrefix string = '10.0.0.0/14'
param subnetPrefix string = '10.0.0.0/24'
param subnetName string = 'default'


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'nsg-${VNetName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-http'
        properties: {
          priority: 1100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vn 'Microsoft.Network/virtualNetworks@2020-06-01' = {
name: VNetName
location: location
properties: {
  addressSpace: {
    addressPrefixes: [
      addressPrefix
    ]
  }
  subnets: [
    {
      name: subnetName
      properties: {
        addressPrefix: subnetPrefix
        networkSecurityGroup: {
          id: networkSecurityGroup.id
        }
      }
    }
  ]
}
}

output outvnetID string = vn.id
output outvnetName string = vn.name
