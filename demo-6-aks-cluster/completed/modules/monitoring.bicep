// ============================================================
// Module: Monitoring
// Enterprise Private AKS - Log Analytics & Diagnostics
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

@description('Log retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// === VARIABLES ===
var logAnalyticsName = 'log-${projectName}-${environmentName}'

// === LOG ANALYTICS WORKSPACE ===

@description('Log Analytics workspace for centralized logging and Container Insights')
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
      dailyQuotaGb: -1 // Unlimited for production; consider setting a cap for dev
    }
    publicNetworkAccessForIngestion: 'Enabled' // Required for Container Insights
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// === SOLUTIONS ===

@description('Container Insights solution for AKS monitoring')
resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalytics.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalytics.id
  }
  plan: {
    name: 'ContainerInsights(${logAnalytics.name})'
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

// === OUTPUTS ===

@description('Log Analytics workspace resource ID')
output logAnalyticsId string = logAnalytics.id

@description('Log Analytics workspace name')
output logAnalyticsName string = logAnalytics.name

@description('Log Analytics workspace customer ID (for agent configuration)')
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId
