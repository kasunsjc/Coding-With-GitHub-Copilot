// ============================================================
// Module: Networking
// ============================================================

@description('Azure region')
param location string

@description('Project name')
param projectName string

@description('Environment name')
param environmentName string

@description('Resource tags')
param tags object

// --- Virtual Network ---
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: '${projectName}-${environmentName}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'data-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          serviceEndpoints: [
            { service: 'Microsoft.Sql' }
            { service: 'Microsoft.Storage' }
          ]
        }
      }
      {
        name: 'pe-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

// --- NSG ---
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: '${projectName}-${environmentName}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// --- Outputs ---
output vnetId string = vnet.id
output appSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
output peSubnetId string = vnet.properties.subnets[2].id
