// ============================================================================
// DEMO 4 — CONTEXT MATTERS: How Existing Code Guides Copilot
// ============================================================================
// This file shows how decorators, parameters, and existing resources
// act as "invisible prompts" that dramatically improve Copilot suggestions.
// ============================================================================

// ---------------------------------------------------------------------------
// TECHNIQUE 1: Parameter Decorators Guide Everything
// ---------------------------------------------------------------------------
// These decorators are NOT just documentation — they shape what Copilot generates.
// Type the parameters below, then let Copilot create resources that USE them.

@description('The Azure region for all resources')
param location string = resourceGroup().location

@description('The deployment environment')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('The project name — used in resource naming')
@minLength(3)
@maxLength(12)
param projectName string

@description('Enable zone redundancy (recommended for prod)')
param zoneRedundant bool = environment == 'prod'

@description('SKU tier based on environment')
@allowed(['Free', 'Basic', 'Standard', 'Premium'])
param appServiceSkuName string = environment == 'prod' ? 'Standard' : 'Basic'

// DEMO: Now type "// Create an App Service Plan" and watch Copilot use
// the appServiceSkuName param, environment tag, and projectName in naming.
// It reads the existing context!


// ---------------------------------------------------------------------------
// TECHNIQUE 2: Existing Resources Create Context Chains
// ---------------------------------------------------------------------------
// When Copilot sees existing resources, it automatically references them.

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${projectName}-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
  tags: {
    environment: environment
    project: projectName
  }
}

// DEMO: Now type "// Create Application Insights" and Copilot will automatically
// reference logAnalytics.id as the workspace — because it sees the resource above!


// ---------------------------------------------------------------------------
// TECHNIQUE 3: Naming Conventions Are Contagious
// ---------------------------------------------------------------------------
// Once you establish a naming pattern, Copilot follows it everywhere.

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-${projectName}-${environment}'     // <-- Copilot learns: vnet-{project}-{env}
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'snet-app'
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
        name: 'snet-data'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
  tags: {
    environment: environment
    project: projectName
  }
}

// DEMO: Now type "// Create a Network Security Group" and Copilot will:
//  1. Name it nsg-{projectName}-{environment} (matching pattern)
//  2. Tag it the same way (matching convention)
//  3. Use the same location variable


// ---------------------------------------------------------------------------
// TECHNIQUE 4: Output Comments Hint at What's Next
// ---------------------------------------------------------------------------
// Adding outputs helps Copilot understand the deployment topology

output vnetId string = vnet.id
output vnetName string = vnet.name
output appSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
output peSubnetId string = vnet.properties.subnets[2].id
output logAnalyticsId string = logAnalytics.id

// DEMO: Now type "// Create a Key Vault with a private endpoint" and Copilot will
// use peSubnetId from the subnet above AND logAnalytics for diagnostic settings!


// ---------------------------------------------------------------------------
// TECHNIQUE 5: File Name Is a Mega-Prompt
// ---------------------------------------------------------------------------
// This file is called context-matters.bicep — generic.
// But imagine files named:
//
//   networking.bicep    → Copilot suggests VNets, NSGs, Route Tables
//   compute.bicep       → Copilot suggests App Service, VMs, AKS
//   security.bicep      → Copilot suggests Key Vault, RBAC, Private Endpoints
//   monitoring.bicep    → Copilot suggests Log Analytics, Alerts, Dashboards
//
// The filename alone shifts Copilot's focus!


// ---------------------------------------------------------------------------
// TECHNIQUE 6: Conditional Patterns Teach Environment Awareness
// ---------------------------------------------------------------------------
// Once Copilot sees one conditional, it applies the pattern to new resources

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: environment == 'prod' ? 'premium' : 'standard'   // <-- Copilot learns this pattern
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enablePurgeProtection: environment == 'prod'               // <-- prod = extra protection
    softDeleteRetentionInDays: environment == 'prod' ? 90 : 7  // <-- environment-aware defaults
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
  tags: {
    environment: environment
    project: projectName
  }
}

// DEMO: Now type "// Create a Storage Account" and Copilot will:
// 1. Use environment-conditional SKU (GRS for prod, LRS for dev)
// 2. Apply environment-conditional soft delete retention
// 3. Follow the same tagging and naming patterns
