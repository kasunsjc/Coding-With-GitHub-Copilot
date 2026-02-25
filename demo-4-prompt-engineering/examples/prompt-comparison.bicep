// ============================================================================
// DEMO 4 — PROMPT COMPARISON: VAGUE vs. SPECIFIC
// ============================================================================
// This file demonstrates how prompt quality directly affects Bicep output.
// Walk through each pair to show the audience the difference.
// ============================================================================

// ---------------------------------------------------------------------------
// EXAMPLE 1: Storage Account
// ---------------------------------------------------------------------------

// ❌ VAGUE PROMPT — Try this first (delete the resource block below before demoing)
// create a storage account

// Copilot will likely generate something minimal like:
resource vagueStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'storage1'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
// Problems: hardcoded name, no TLS enforcement, no soft delete, no tags, public access open

// ✅ SPECIFIC PROMPT — Now try this:
// Create an Azure Storage Account with Standard_GRS redundancy, StorageV2 kind,
// TLS 1.2 minimum, HTTPS only, blob public access disabled,
// blob soft delete 14 days, container soft delete 7 days.
// Tag with environment and project. Name: st{project}{env}{uniqueString}.

@description('The deployment environment')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Project identifier for naming')
@minLength(2)
@maxLength(8)
param project string

param location string = resourceGroup().location

resource specificStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${project}${environment}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
  tags: {
    environment: environment
    project: project
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: specificStorage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 14
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// ---------------------------------------------------------------------------
// EXAMPLE 2: Key Vault
// ---------------------------------------------------------------------------

// ❌ VAGUE: "create a key vault"
resource vagueKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'myvault'
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: []
  }
}
// Problems: no RBAC, soft delete defaults, no purge protection, no network rules

// ✅ SPECIFIC:
// Create an Azure Key Vault with RBAC authorization (not access policies),
// purge protection enabled, soft delete 90 days, TLS 1.2 minimum,
// private-endpoint-ready (default deny network rules),
// diagnostic settings ready. Tag with environment and project.
resource specificKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${project}-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    publicNetworkAccess: 'Disabled'
  }
  tags: {
    environment: environment
    project: project
  }
}

// ---------------------------------------------------------------------------
// EXAMPLE 3: SQL Database
// ---------------------------------------------------------------------------

// ❌ VAGUE: "create a sql database"
// → Copilot may skip: firewalls, Entra auth, auditing, TDE, connection policy

// ✅ SPECIFIC:
// Create Azure SQL Server with Entra-only authentication (no SQL auth),
// minimum TLS 1.2, public network access disabled, auditing enabled
// to a storage account, a General Purpose database on Standard-series S1 DTU tier.
// The SQL admin should be an Entra group (passed as parameter).

@description('Object ID of the Entra group for SQL admin')
param sqlAdminGroupObjectId string

@description('Display name of the Entra group for SQL admin')
param sqlAdminGroupName string = 'SQL-Admins'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-${project}-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: sqlAdminGroupName
      sid: sqlAdminGroupObjectId
      tenantId: tenant().tenantId
      principalType: 'Group'
    }
  }
  tags: {
    environment: environment
    project: project
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: 'sqldb-${project}-${environment}'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 268435456000 // 250 GB
    zoneRedundant: false
  }
  tags: {
    environment: environment
    project: project
  }
}
