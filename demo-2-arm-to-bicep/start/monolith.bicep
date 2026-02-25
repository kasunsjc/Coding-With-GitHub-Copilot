// ============================================================
// Demo 2: Monolith Bicep file — everything in one place
// ============================================================
// This is a single large file that should be refactored into
// modules. Use Copilot Chat to extract into a modular structure.
// ============================================================

targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environmentName string
param projectName string
param sqlAdminGroupObjectId string

var tags = {
  environment: environmentName
  project: projectName
}

// --- Networking (should become a module) ---
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: '${projectName}-${environmentName}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'data-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          serviceEndpoints: [
            { service: 'Microsoft.Sql' }
            { service: 'Microsoft.Storage' }
          ]
        }
      }
      {
        name: 'pe-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: '${projectName}-${environmentName}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// --- Compute (should become a module) ---
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

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: '${projectName}-${environmentName}-app'
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}

// --- Data (should become a module) ---
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: '${projectName}-${environmentName}-sql'
  location: location
  tags: tags
  properties: {
    minimalTlsVersion: '1.2'
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      login: 'sqladmingroup'
      sid: sqlAdminGroupObjectId
      tenantId: subscription().tenantId
    }
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: '${projectName}-db'
  location: location
  tags: tags
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${replace(projectName, '-', '')}${environmentName}st'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// --- Monitoring (should become a module) ---
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-${environmentName}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${projectName}-${environmentName}-ai'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}
