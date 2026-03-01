// ============================================================
// Module: Azure Bastion
// Hub & Spoke VNet - Secure RDP/SSH access to VMs without public IPs
// ============================================================

@description('Azure region for all resources')
param location string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Short location code used for resource naming (e.g. aue, eus, weu)')
param locationCode string

@description('Azure Bastion subnet resource ID (must be AzureBastionSubnet)')
param bastionSubnetId string

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsId string

@description('Resource tags')
param tags object

// === VARIABLES ===

var bastionPublicIpName = 'pip-bas-hub-${environmentName}-${locationCode}'
var bastionName = 'bas-hub-${environmentName}-${locationCode}'

// === BASTION PUBLIC IP ===

@description('Public IP for Azure Bastion - Standard SKU required')
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  zones: ['1', '2', '3'] // Zone-redundant
}

// === AZURE BASTION ===

@description('Azure Bastion Standard - provides secure RDP/SSH access to VMs in all peered spokes')
resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Standard enables tunneling, IP connect, and shareable links
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
    enableTunneling: true // Allows native SSH/RDP client connections
    enableIpConnect: true // Allows connecting to VMs by IP address
    enableShareableLink: false // Disabled for security
  }
}

// === DIAGNOSTIC SETTINGS ===

@description('Diagnostic settings for Azure Bastion')
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${bastionName}'
  scope: bastion
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// === OUTPUTS ===

@description('Azure Bastion resource ID')
output bastionId string = bastion.id

@description('Azure Bastion name')
output bastionName string = bastion.name

@description('Azure Bastion public IP address')
output bastionPublicIp string = bastionPublicIp.properties.ipAddress
