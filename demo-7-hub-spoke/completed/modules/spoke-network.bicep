// ============================================================
// Module: Spoke Network (Reusable)
// Hub & Spoke VNet - Spoke Virtual Network, Subnets & NSGs
// This module is reusable across multiple spoke deployments
// ============================================================

@description('Azure region for all resources')
param location string

@description('Spoke purpose/name identifier (e.g. identity, workload, dmz)')
param spokePurpose string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Short location code used for resource naming (e.g. aue, eus, weu)')
param locationCode string

@description('Address prefix for the spoke VNet (e.g. 10.1.0.0/16)')
param spokeVnetAddressPrefix string

@description('Address prefix for the primary workload subnet (e.g. 10.1.0.0/24)')
param workloadSubnetAddressPrefix string

@description('Address prefix for the data subnet (e.g. 10.1.1.0/24) - optional secondary subnet')
param dataSubnetAddressPrefix string = ''

@description('Route table resource ID to associate with the workload subnet (leave empty to skip)')
param routeTableId string = ''

@description('Route table resource ID to associate with the data subnet (leave empty to skip)')
param dataRouteTableId string = ''

@description('Resource tags')
param tags object

// === VARIABLES ===

var spokeVnetName = 'vnet-spoke-${spokePurpose}-${environmentName}-${locationCode}'
var hasDataSubnet = !empty(dataSubnetAddressPrefix)
var hasRouteTable = !empty(routeTableId)
var hasDataRouteTable = !empty(dataRouteTableId)

// === NETWORK SECURITY GROUPS ===

@description('NSG for workload subnet - deny all inbound by default, route through Firewall')
resource nsgWorkload 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${spokePurpose}-${environmentName}'
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

@description('NSG for data subnet - restrict to workload subnet only')
resource nsgData 'Microsoft.Network/networkSecurityGroups@2024-05-01' = if (hasDataSubnet) {
  name: 'nsg-${spokePurpose}-data-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowWorkloadSubnetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: workloadSubnetAddressPrefix
          destinationAddressPrefix: dataSubnetAddressPrefix
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

// === SPOKE VIRTUAL NETWORK ===

@description('Spoke virtual network for the specified purpose/workload')
resource spokeVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: spokeVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [spokeVnetAddressPrefix]
    }
    subnets: hasDataSubnet
      ? [
          {
            name: 'snet-${spokePurpose}-${environmentName}'
            properties: {
              addressPrefix: workloadSubnetAddressPrefix
              networkSecurityGroup: {
                id: nsgWorkload.id
              }
              routeTable: hasRouteTable ? { id: routeTableId } : null
            }
          }
          {
            name: 'snet-${spokePurpose}-data-${environmentName}'
            properties: {
              addressPrefix: dataSubnetAddressPrefix
              networkSecurityGroup: {
                id: nsgData.id
              }
              routeTable: hasDataRouteTable ? { id: dataRouteTableId } : (hasRouteTable ? { id: routeTableId } : null)
            }
          }
        ]
      : [
          {
            name: 'snet-${spokePurpose}-${environmentName}'
            properties: {
              addressPrefix: workloadSubnetAddressPrefix
              networkSecurityGroup: {
                id: nsgWorkload.id
              }
              routeTable: hasRouteTable ? { id: routeTableId } : null
            }
          }
        ]
  }
}

// === OUTPUTS ===

@description('Spoke virtual network resource ID')
output spokeVnetId string = spokeVnet.id

@description('Spoke virtual network name')
output spokeVnetName string = spokeVnet.name

@description('Spoke virtual network address prefix')
output spokeVnetAddressPrefix string = spokeVnetAddressPrefix

@description('Primary workload subnet resource ID')
output workloadSubnetId string = spokeVnet.properties.subnets[0].id

@description('Data subnet resource ID (empty if not deployed)')
output dataSubnetId string = hasDataSubnet ? spokeVnet.properties.subnets[1].id : ''
