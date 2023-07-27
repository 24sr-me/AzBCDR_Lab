targetScope = 'resourceGroup'

param publicIpName string
param location string =  resourceGroup().location
param dnsName string

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

output outpublicIP string = publicIp.properties.ipAddress
output outID string = publicIp.id
