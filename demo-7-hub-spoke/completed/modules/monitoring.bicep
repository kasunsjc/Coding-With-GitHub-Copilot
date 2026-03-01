// ============================================================
// Module: Monitoring
// Hub & Spoke VNet - Log Analytics Workspace for centralized logging
// ============================================================

@description('Azure region for all resources')
param location string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Short location code used for resource naming (e.g. aue, eus, weu)')
param locationCode string

@description('Log retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Resource tags')
param tags object

// === VARIABLES ===

var logAnalyticsName = 'log-hub-${environmentName}-${locationCode}'

// === LOG ANALYTICS WORKSPACE ===

@description('Centralised Log Analytics workspace for hub-spoke network diagnostics and security events')
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// === OUTPUTS ===

@description('Log Analytics workspace resource ID')
output logAnalyticsId string = logAnalytics.id

@description('Log Analytics workspace name')
output logAnalyticsName string = logAnalytics.name

@description('Log Analytics workspace customer ID')
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId
