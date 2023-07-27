@description('Set the local VNet name')
param VirtualNetworkName string

@description('Set the remote VNet name')
param RemoteVirtualNetworkID string

resource existingLocalVirtualNetworkName_peering_to_remote_vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${VirtualNetworkName}/peering-to-remote-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: RemoteVirtualNetworkID
    }
  }
}
