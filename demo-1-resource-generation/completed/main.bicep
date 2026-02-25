// ============================================================
// Demo 1: Resource Generation — COMPLETED REFERENCE
// ============================================================
// This is the expected output after Copilot generates the code.
// Your live demo results may vary slightly — that's expected!
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
param environmentName string = 'dev'

@description('Project name used for resource naming')
@maxLength(12)
param projectName string

// --- Variables ---
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${projectName}-${environmentName}'
var tags = {
  environment: environmentName
  project: projectName
  managedBy: 'bicep'
}

// --- Resource 1: Storage Account ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${replace(projectName, '-', '')}${environmentName}${uniqueSuffix}'
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
    accessTier: 'Hot'
  }
}

// --- Resource 2: Virtual Network ---
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: '${resourcePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'data-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// --- Resource 3: App Service Plan ---
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

// --- Resource 4: Key Vault ---
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${resourcePrefix}-kv'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// --- Resource 5: SQL Server and Database ---
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: '${resourcePrefix}-sql'
  location: location
  tags: tags
  properties: {
    minimalTlsVersion: '1.2'
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      login: 'sqladmingroup'
      sid: '00000000-0000-0000-0000-000000000000' // Replace with actual AAD group object ID
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
  properties: {
    maxSizeBytes: 2147483648 // 2GB
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// --- Outputs ---
output storageAccountName string = storageAccount.name
output keyVaultUri string = keyVault.properties.vaultUri
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output virtualNetworkId string = virtualNetwork.id
output appServicePlanId string = appServicePlan.id
