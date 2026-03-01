// ============================================================
// Module: Azure Firewall
// Hub & Spoke VNet - Azure Firewall Premium with Policy
// Central egress and east-west traffic inspection
// ============================================================

@description('Azure region for all resources')
param location string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Short location code used for resource naming (e.g. aue, eus, weu)')
param locationCode string

@description('Azure Firewall subnet resource ID (must be AzureFirewallSubnet)')
param firewallSubnetId string

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsId string

@description('Resource tags')
param tags object

// === VARIABLES ===

var firewallPolicyName = 'afwp-hub-${environmentName}-${locationCode}'
var firewallName = 'afw-hub-${environmentName}-${locationCode}'
var firewallPublicIpName = 'pip-afw-hub-${environmentName}-${locationCode}'

// === FIREWALL PUBLIC IP ===

@description('Public IP for Azure Firewall - Standard SKU required for Firewall')
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: firewallPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  zones: ['1', '2', '3'] // Zone-redundant for production
}

// === FIREWALL POLICY ===

@description('Azure Firewall Premium Policy - enables IDPS, TLS inspection, and URL filtering')
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: firewallPolicyName
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Premium' // Premium for IDPS and TLS inspection
    }
    threatIntelMode: 'Alert' // Alert on known malicious IPs/domains
    insights: {
      isEnabled: true
      retentionDays: 30
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: logAnalyticsId
        }
        workspaces: [
          {
            region: location
            workspaceId: {
              id: logAnalyticsId
            }
          }
        ]
      }
    }
    intrusionDetection: {
      mode: 'Alert' // Detect and alert on intrusion attempts
    }
    dnsSettings: {
      enableProxy: true // Enable DNS proxy for spoke VNets
    }
  }
}

// === DEFAULT NETWORK RULE COLLECTION GROUP ===

@description('Default network rule collection - allow hub-spoke traffic')
resource defaultNetworkRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRules'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowHubSpokeTraffic'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowInterSpokeTraffic'
            description: 'Allow traffic between spoke VNets via the firewall'
            ipProtocols: ['Any']
            sourceAddresses: ['10.0.0.0/8']
            destinationAddresses: ['10.0.0.0/8']
            destinationPorts: ['*']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowInternetEgress'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowDNS'
            description: 'Allow DNS resolution'
            ipProtocols: ['UDP', 'TCP']
            sourceAddresses: ['10.0.0.0/8']
            destinationAddresses: ['*']
            destinationPorts: ['53']
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowNTP'
            description: 'Allow NTP time synchronisation'
            ipProtocols: ['UDP']
            sourceAddresses: ['10.0.0.0/8']
            destinationAddresses: ['*']
            destinationPorts: ['123']
          }
        ]
      }
    ]
  }
}

// === DEFAULT APPLICATION RULE COLLECTION GROUP ===

@description('Default application rule collection - allow common Azure services')
resource defaultAppRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRules'
  dependsOn: [defaultNetworkRuleGroup]
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowAzureServices'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'AllowWindowsUpdate'
            description: 'Allow Windows Update'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            targetFqdns: [
              'windowsupdate.microsoft.com'
              '*.windowsupdate.microsoft.com'
              'update.microsoft.com'
            ]
            sourceAddresses: ['10.0.0.0/8']
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowAzureMonitor'
            description: 'Allow Azure Monitor and Log Analytics agent traffic'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: ['AzureMonitor']
            sourceAddresses: ['10.0.0.0/8']
          }
        ]
      }
    ]
  }
}

// === AZURE FIREWALL ===

@description('Azure Firewall Premium - central egress and traffic inspection for hub-spoke')
resource firewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: firewallName
  location: location
  tags: tags
  zones: ['1', '2', '3'] // Zone-redundant for production
  properties: {
    sku: {
      tier: 'Premium'
      name: 'AZFW_VNet'
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
  dependsOn: [defaultAppRuleGroup]
}

// === DIAGNOSTIC SETTINGS ===

@description('Diagnostic settings for Azure Firewall')
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${firewallName}'
  scope: firewall
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// === OUTPUTS ===

@description('Azure Firewall resource ID')
output firewallId string = firewall.id

@description('Azure Firewall name')
output firewallName string = firewall.name

@description('Azure Firewall private IP address (used as next hop in route tables)')
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress

@description('Azure Firewall public IP address')
output firewallPublicIp string = firewallPublicIp.properties.ipAddress

@description('Firewall policy resource ID')
output firewallPolicyId string = firewallPolicy.id
