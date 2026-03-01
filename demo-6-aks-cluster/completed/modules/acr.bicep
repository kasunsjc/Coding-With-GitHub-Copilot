// ============================================================
// Module: Azure Container Registry
// Enterprise Private AKS - Private ACR with Premium SKU
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

@description('ACR private DNS zone resource ID')
param acrDnsZoneId string

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsId string

// === VARIABLES ===
// ACR name must be globally unique, alphanumeric only
var acrName = 'acr${replace(projectName, '-', '')}${environmentName}${uniqueString(resourceGroup().id)}'

// === CONTAINER REGISTRY ===

@description('Azure Container Registry with Premium SKU for private endpoint support')
resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Premium' // Premium required for private endpoint and geo-replication
  }
  properties: {
    adminUserEnabled: false // Disable admin user - use managed identity
    publicNetworkAccess: 'Disabled' // No public access
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled' // Enable for production in supported regions
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled' // Enable for content trust
      }
      retentionPolicy: {
        days: 30
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled' // Enable with customer-managed key for enhanced security
    }
    dataEndpointEnabled: false
  }
}

// === PRIVATE ENDPOINT ===

@description('Private endpoint for Container Registry')
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${acrName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointsSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${acrName}-connection'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: ['registry']
        }
      }
    ]
  }
}

@description('Private DNS zone group for ACR private endpoint')
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: acrDnsZoneId
        }
      }
    ]
  }
}

// === DIAGNOSTIC SETTINGS ===

@description('Diagnostic settings for Container Registry')
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${acrName}'
  scope: acr
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

@description('Container Registry resource ID')
output acrId string = acr.id

@description('Container Registry name')
output acrName string = acr.name

@description('Container Registry login server')
output acrLoginServer string = acr.properties.loginServer
