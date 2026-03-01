// ============================================================
// Module: Key Vault
// Enterprise Private AKS - Secrets Management with Private Endpoint
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

@description('Private endpoints subnet resource ID')
param privateEndpointsSubnetId string

@description('Key Vault private DNS zone resource ID')
param keyVaultDnsZoneId string

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsId string

// === VARIABLES ===
var keyVaultName = 'kv-${projectName}-${environmentName}-${uniqueString(resourceGroup().id)}'

// === KEY VAULT ===

@description('Key Vault for secrets management with RBAC authorization')
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true // Use Azure RBAC instead of access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true // Prevent permanent deletion
    publicNetworkAccess: 'Disabled' // No public access - private endpoint only
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// === PRIVATE ENDPOINT ===

@description('Private endpoint for Key Vault')
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${keyVaultName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointsSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${keyVaultName}-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

@description('Private DNS zone group for Key Vault private endpoint')
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: keyVaultDnsZoneId
        }
      }
    ]
  }
}

// === DIAGNOSTIC SETTINGS ===

@description('Diagnostic settings for Key Vault')
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${keyVaultName}'
  scope: keyVault
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

@description('Key Vault resource ID')
output keyVaultId string = keyVault.id

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri
