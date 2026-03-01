// ============================================================
// Module: Azure Bastion
// Enterprise Private AKS - Secure Access to Jump Box
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

@description('Bastion subnet resource ID')
param bastionSubnetId string

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsId string

// === VARIABLES ===
var bastionName = 'bas-${projectName}-${environmentName}'
var publicIpName = 'pip-${bastionName}'

// === PUBLIC IP ===

@description('Public IP address for Azure Bastion')
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// === AZURE BASTION ===

@description('Azure Bastion host for secure VM access')
resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Standard SKU for native client support and file transfer
  }
  properties: {
    disableCopyPaste: false
    enableFileCopy: true // Enable file copy for kubectl config transfer
    enableIpConnect: false
    enableKerberos: false
    enableShareableLink: false
    enableTunneling: true // Enable native client support (az network bastion tunnel)
    scaleUnits: 2
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
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
