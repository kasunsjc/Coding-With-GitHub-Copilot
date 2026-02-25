// ============================================================
// Demo 2: Modular Refactoring — COMPLETED REFERENCE (main.bicep)
// ============================================================
// This is the result of refactoring monolith.bicep into modules.
// ============================================================

targetScope = 'resourceGroup'

// --- Parameters ---
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Project name')
@maxLength(12)
param projectName string

@description('Object ID of the Azure AD group for SQL admin')
param sqlAdminGroupObjectId string

// --- Variables ---
var tags = {
  environment: environmentName
  project: projectName
  managedBy: 'bicep'
}

// --- Module: Networking ---
module networking 'modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
  }
}

// --- Module: Compute ---
module compute 'modules/compute.bicep' = {
  name: 'compute-deployment'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    appSubnetId: networking.outputs.appSubnetId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
  }
}

// --- Module: Data ---
module data 'modules/data.bicep' = {
  name: 'data-deployment'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    sqlAdminGroupObjectId: sqlAdminGroupObjectId
  }
}

// --- Module: Monitoring ---
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
  }
}

// --- Outputs ---
output webAppUrl string = compute.outputs.webAppUrl
output sqlServerFqdn string = data.outputs.sqlServerFqdn
output storageAccountName string = data.outputs.storageAccountName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
