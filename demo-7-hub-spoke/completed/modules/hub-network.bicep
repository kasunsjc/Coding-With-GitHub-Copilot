// ============================================================
// Module: Hub Network
// Hub & Spoke VNet - Hub Virtual Network, Subnets & NSGs
// Following CAF/Landing Zone patterns
// ============================================================

@description('Azure region for all resources')
param location string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Short location code used for resource naming (e.g. aue, eus, weu)')
param locationCode string

@description('Resource tags')
param tags object

// === VARIABLES ===

var hubVnetName = 'vnet-hub-${environmentName}-${locationCode}'
var hubVnetAddressPrefix = '10.0.0.0/16'

// Subnet definitions following CAF naming conventions
// AzureFirewallSubnet must be /26 minimum; AzureBastionSubnet must be /26 minimum
var subnets = {
  firewall: {
    name: 'AzureFirewallSubnet' // Required name for Azure Firewall
    addressPrefix: '10.0.0.0/26'
  }
  bastion: {
    name: 'AzureBastionSubnet' // Required name for Azure Bastion
    addressPrefix: '10.0.1.0/26'
  }
  gateway: {
    name: 'GatewaySubnet' // Required name for VPN/ER Gateway
    addressPrefix: '10.0.2.0/27'
  }
  shared: {
    name: 'snet-shared-${environmentName}'
    addressPrefix: '10.0.3.0/24' // Shared services (DNS, management)
  }
}

// === NETWORK SECURITY GROUPS ===

@description('NSG for shared services subnet in hub')
resource nsgShared 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-shared-${environmentName}'
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

// === HUB VIRTUAL NETWORK ===

@description('Hub virtual network - central connectivity hub for all spoke VNets')
resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [hubVnetAddressPrefix]
    }
    subnets: [
      {
        // Azure Firewall does not support NSG on its dedicated subnet
        name: subnets.firewall.name
        properties: {
          addressPrefix: subnets.firewall.addressPrefix
        }
      }
      {
        // Azure Bastion does not support NSG on its dedicated subnet (uses its own rules)
        name: subnets.bastion.name
        properties: {
          addressPrefix: subnets.bastion.addressPrefix
        }
      }
      {
        // Gateway subnet must not have NSG
        name: subnets.gateway.name
        properties: {
          addressPrefix: subnets.gateway.addressPrefix
        }
      }
      {
        name: subnets.shared.name
        properties: {
          addressPrefix: subnets.shared.addressPrefix
          networkSecurityGroup: {
            id: nsgShared.id
          }
        }
      }
    ]
  }
}

// === OUTPUTS ===

@description('Hub virtual network resource ID')
output hubVnetId string = hubVnet.id

@description('Hub virtual network name')
output hubVnetName string = hubVnet.name

@description('Hub virtual network address prefix')
output hubVnetAddressPrefix string = hubVnetAddressPrefix

@description('Azure Firewall subnet resource ID')
output firewallSubnetId string = hubVnet.properties.subnets[0].id

@description('Azure Bastion subnet resource ID')
output bastionSubnetId string = hubVnet.properties.subnets[1].id

@description('Gateway subnet resource ID')
output gatewaySubnetId string = hubVnet.properties.subnets[2].id

@description('Shared services subnet resource ID')
output sharedSubnetId string = hubVnet.properties.subnets[3].id
