// ============================================================================
// DEMO 5 — SECURITY AWARENESS: Anti-Patterns vs. Secure Patterns
// ============================================================================
// This file shows common insecure Bicep patterns that Copilot might generate
// WITHOUT proper instructions, and the secure alternatives WITH instructions.
// ============================================================================

// ---------------------------------------------------------------------------
// ANTI-PATTERN 1: Hardcoded Secrets
// ---------------------------------------------------------------------------

// ❌ INSECURE — password visible in plain text, stored in version control
param insecurePassword string = 'P@ssw0rd123!'

resource insecureSqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-insecure-demo'
  location: resourceGroup().location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: insecurePassword   // ← Credential in source code!
  }
}

// ✅ SECURE — use @secure decorator + Entra-only authentication
@secure()
@description('SQL admin password — passed via Key Vault reference or pipeline secret')
param securePassword string

// Even better: use Entra-only auth (no SQL password at all)
param sqlAdminGroupObjectId string
param sqlAdminGroupName string = 'SQL-Admins'

resource secureSqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: 'sql-secure-demo-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true           // ← No SQL auth at all
      login: sqlAdminGroupName
      sid: sqlAdminGroupObjectId
      tenantId: tenant().tenantId
      principalType: 'Group'
    }
  }
}

// GUARDRAIL: Bicep linter rule `no-hardcoded-env-urls` + PR checklist "No hardcoded secrets"


// ---------------------------------------------------------------------------
// ANTI-PATTERN 2: Public Blob Access
// ---------------------------------------------------------------------------

// ❌ INSECURE — blobs can be accessed anonymously
resource insecureStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stinsecuredemo${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true       // ← Anyone on the internet can read blobs
    // No TLS enforcement
    // No network rules
  }
}

// ✅ SECURE — locked down storage
resource secureStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stsecuredemo${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: { name: 'Standard_GRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false        // ← No anonymous access
    supportsHttpsTrafficOnly: true      // ← HTTPS only
    minimumTlsVersion: 'TLS1_2'        // ← Modern TLS
    networkAcls: {
      defaultAction: 'Deny'            // ← Deny all by default
      bypass: 'AzureServices'
    }
  }
}

// GUARDRAIL: Azure Policy `Deny-Storage-PublicAccess` + linter warning


// ---------------------------------------------------------------------------
// ANTI-PATTERN 3: Overly Permissive Network Rules
// ---------------------------------------------------------------------------

// ❌ INSECURE — Key Vault open to entire internet
resource insecureKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-insecure-demo'
  location: resourceGroup().location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: '00000000-0000-0000-0000-000000000000'  // ← Who is this?
        permissions: {
          secrets: [ 'all' ]          // ← Full access to all secrets!
          keys: [ 'all' ]             // ← Full access to all keys!
          certificates: [ 'all' ]     // ← Full access to all certs!
        }
      }
    ]
  }
}

// ✅ SECURE — RBAC-based, network-restricted Key Vault
resource secureKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-secure-demo-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true       // ← RBAC instead of access policies
    enablePurgeProtection: true         // ← Prevent accidental deletion
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'     // ← Not accessible from internet
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Then grant specific, least-privilege RBAC roles:
param appServicePrincipalId string

resource kvSecretReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(secureKeyVault.id, appServicePrincipalId, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: secureKeyVault
  properties: {
    principalId: appServicePrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'  // Key Vault Secrets User (read-only)
    )
    principalType: 'ServicePrincipal'
  }
}

// GUARDRAIL: Azure Policy `Key vaults should use RBAC` + PR checklist


// ---------------------------------------------------------------------------
// ANTI-PATTERN 4: Missing Managed Identity
// ---------------------------------------------------------------------------

// ❌ INSECURE — connection string with credentials
resource insecureWebApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-insecure-demo'
  location: resourceGroup().location
  properties: {
    serverFarmId: 'some-plan-id'
    siteConfig: {
      appSettings: [
        {
          name: 'DATABASE_CONNECTION'
          value: 'Server=myserver.database.windows.net;Database=mydb;User=admin;Password=P@ssw0rd!'
          // ← Credentials in app settings! Visible in portal!
        }
      ]
    }
  }
}

// ✅ SECURE — managed identity + Key Vault references
resource secureWebApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-secure-demo-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'              // ← Managed identity, no credentials to manage
  }
  properties: {
    serverFarmId: 'some-plan-id'
    siteConfig: {
      appSettings: [
        {
          name: 'DATABASE_CONNECTION'
          value: '@Microsoft.KeyVault(SecretUri=https://kv-secure.vault.azure.net/secrets/db-connection/)'
          // ← Key Vault reference — secret never in app settings
        }
      ]
    }
  }
}

// GUARDRAIL: copilot-instructions.md says "Use managed identity over connection strings"
