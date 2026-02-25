// ============================================================
// Module: Compute (App Service Plan + Web App)
// ============================================================

@description('Azure region')
param location string

@description('Project name')
param projectName string

@description('Environment name')
param environmentName string

@description('Resource tags')
param tags object

@description('Subnet ID for VNet integration')
param appSubnetId string

@description('Application Insights connection string')
param appInsightsConnectionString string

// --- App Service Plan ---
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${projectName}-${environmentName}-plan'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'P1v3'
  }
  properties: {
    reserved: true
  }
}

// --- Web App ---
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: '${projectName}-${environmentName}-app'
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: appSubnetId
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

// --- Outputs ---
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output appServicePlanId string = appServicePlan.id
