// ============================================================
// Module: Networking
// Enterprise Private AKS - Virtual Network & Network Security
// ============================================================

@description('Azure region for all resources')
param location string

@description('Project name used for resource naming')
param projectName string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Resource tags')
param tags object

// === VARIABLES ===
var vnetName = 'vnet-${projectName}-${environmentName}-${location}'
var vnetAddressPrefix = '10.0.0.0/16'

// Subnet configuration
var subnets = {
  aks: {
    name: 'snet-aks-${environmentName}'
    addressPrefix: '10.0.0.0/22' // /22 = 1024 IPs for AKS nodes and pods
  }
  privateEndpoints: {
    name: 'snet-pe-${environmentName}'
    addressPrefix: '10.0.4.0/24'
  }
  bastion: {
    name: 'AzureBastionSubnet' // Must be exactly this name
    addressPrefix: '10.0.5.0/26' // /26 minimum for Bastion
  }
  jumpbox: {
    name: 'snet-jumpbox-${environmentName}'
    addressPrefix: '10.0.6.0/24'
  }
}

// === NETWORK SECURITY GROUPS ===

@description('NSG for AKS subnet - allows required AKS traffic')
resource nsgAks 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-aks-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVnetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

@description('NSG for Private Endpoints subnet')
resource nsgPrivateEndpoints 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-pe-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVnetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

@description('NSG for Jump Box subnet')
resource nsgJumpbox 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-jumpbox-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowBastionInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: subnets.bastion.addressPrefix
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// === VIRTUAL NETWORK ===

@description('Virtual network for AKS and supporting resources')
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: subnets.aks.name
        properties: {
          addressPrefix: subnets.aks.addressPrefix
          networkSecurityGroup: {
            id: nsgAks.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: subnets.privateEndpoints.name
        properties: {
          addressPrefix: subnets.privateEndpoints.addressPrefix
          networkSecurityGroup: {
            id: nsgPrivateEndpoints.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: subnets.bastion.name
        properties: {
          addressPrefix: subnets.bastion.addressPrefix
          // Bastion subnet does not support NSG attachment in the same way
        }
      }
      {
        name: subnets.jumpbox.name
        properties: {
          addressPrefix: subnets.jumpbox.addressPrefix
          networkSecurityGroup: {
            id: nsgJumpbox.id
          }
        }
      }
    ]
  }
}

// === OUTPUTS ===

@description('Virtual network resource ID')
output vnetId string = vnet.id

@description('Virtual network name')
output vnetName string = vnet.name

@description('AKS subnet resource ID')
output aksSubnetId string = vnet.properties.subnets[0].id

@description('Private endpoints subnet resource ID')
output privateEndpointsSubnetId string = vnet.properties.subnets[1].id

@description('Bastion subnet resource ID')
output bastionSubnetId string = vnet.properties.subnets[2].id

@description('Jump box subnet resource ID')
output jumpboxSubnetId string = vnet.properties.subnets[3].id
