// ============================================================
// Demo 2: ARM to Bicep — COMPLETED REFERENCE
// ============================================================
// This is the converted version of legacy-arm-template.json
// ============================================================

targetScope = 'resourceGroup'

// --- Parameters ---
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string

@description('Application name used for resource naming')
@maxLength(12)
param appName string

// --- Variables ---
var storageAccountName = 'st${appName}${uniqueString(resourceGroup().id)}'
var resourcePrefix = '${appName}-${environmentName}'
var tags = {
  environment: environmentName
  managedBy: 'bicep'
}

// --- Log Analytics Workspace ---
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${resourcePrefix}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// --- Application Insights ---
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcePrefix}-ai'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// --- Storage Account ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// --- App Service Plan ---
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${resourcePrefix}-plan'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
  }
  properties: {
    reserved: true
  }
}

// --- Web App ---
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: '${resourcePrefix}-app'
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
  }
}

// --- Outputs ---
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output storageAccountName string = storageAccount.name
