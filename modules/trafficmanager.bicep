@description('Relative DNS name for the traffic manager profile, must be globally unique.')
param uniqueDnsName string
param name string
param prodlocation string
param drlocation string
param prodep1 string
param prodep2 string
param drdep1 string
param drdep2 string

resource ExternalEndpointExample 'Microsoft.Network/trafficmanagerprofiles@2018-08-01' = {
  name: name
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'
    dnsConfig: {
      relativeName: uniqueDnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
      expectedStatusCodeRanges: [
        {
          min: 200
          max: 202
        }
        {
          min: 301
          max: 302
        }
      ]
    }
    endpoints: [
      {
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        name: '${name}-ep1'
        properties: {
          targetResourceId: prodep1
          endpointStatus: 'Enabled'
          endpointLocation: prodlocation
        }
      }
      {
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        name: '${name}-ep2'
        properties: {
          targetResourceId: prodep2
          endpointStatus: 'Enabled'
          endpointLocation: prodlocation
        }
      }
      {
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        name: 'dr-${name}-ep1'
        properties: {
          targetResourceId: drdep1
          endpointStatus: 'Enabled'
          endpointLocation: drlocation
        }
      }
      {
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        name: 'dr-${name}-ep2'
        properties: {
          targetResourceId: drdep2
          endpointStatus: 'Enabled'
          endpointLocation: drlocation
        }
      }
    ]
  }
}
