// ============================================================
// Module: Data (SQL Server + Database + Storage Account)
// ============================================================

@description('Azure region')
param location string

@description('Project name')
param projectName string

@description('Environment name')
param environmentName string

@description('Resource tags')
param tags object

@description('AAD group object ID for SQL admin')
param sqlAdminGroupObjectId string

// --- SQL Server ---
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

// --- SQL Database ---
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

// --- Storage Account ---
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

// --- Outputs ---
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
