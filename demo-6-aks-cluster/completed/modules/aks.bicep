// ============================================================
// Module: Azure Kubernetes Service
// Enterprise Private AKS - Fully Private Cluster
// ============================================================

@description('Azure region for all resources')
param location string

@description('Project name used for resource naming')
param projectName string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Resource tags')
param tags object

@description('AKS subnet resource ID')
param aksSubnetId string

@description('Log Analytics workspace resource ID for Container Insights')
param logAnalyticsId string

@description('Kubernetes version')
param kubernetesVersion string = '1.29'

@description('System node pool VM size')
param systemNodeVmSize string = 'Standard_D4s_v5'

@description('System node pool node count')
@minValue(1)
@maxValue(10)
param systemNodeCount int = 2

@description('User node pool VM size')
param userNodeVmSize string = 'Standard_D4s_v5'

@description('User node pool node count')
@minValue(1)
@maxValue(100)
param userNodeCount int = 3

@description('Object ID of the Entra ID group for AKS cluster administrators')
param aksAdminGroupObjectId string

@description('AKS private DNS zone resource ID (optional, use system for auto-created)')
param privateDnsZoneId string = ''

// === VARIABLES ===
var aksName = 'aks-${projectName}-${environmentName}-${location}'
var nodeResourceGroupName = 'rg-${aksName}-nodes'

// Determine private DNS zone mode
var privateDnsZoneMode = empty(privateDnsZoneId) ? 'system' : privateDnsZoneId

// === AKS CLUSTER ===

@description('Private AKS cluster with Entra ID integration and Azure RBAC')
resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: aksName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Standard' // Standard tier for production SLA
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: aksName
    nodeResourceGroup: nodeResourceGroupName
    enableRBAC: true
    
    // === PRIVATE CLUSTER CONFIGURATION ===
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: privateDnsZoneMode
      enablePrivateClusterPublicFQDN: false // No public FQDN
    }

    // === NETWORK CONFIGURATION ===
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay' // Azure CNI Overlay
      networkPolicy: 'azure' // Azure Network Policy
      networkDataplane: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
    }

    // === ENTRA ID & AZURE RBAC ===
    aadProfile: {
      managed: true
      enableAzureRBAC: true // Use Azure RBAC for Kubernetes authorization
      adminGroupObjectIDs: [aksAdminGroupObjectId]
    }
    disableLocalAccounts: true // Force Entra ID authentication

    // === ADDONS ===
    addonProfiles: {
      // Container Insights for monitoring
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsId
          useAADAuth: 'true'
        }
      }
      // Azure Policy for Kubernetes
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      // Key Vault Secrets Provider (CSI Driver)
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
    }

    // === SECURITY ===
    securityProfile: {
      defender: {
        securityMonitoring: {
          enabled: true
        }
        logAnalyticsWorkspaceResourceId: logAnalyticsId
      }
      imageCleaner: {
        enabled: true
        intervalHours: 48
      }
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true // Required for workload identity
    }

    // === AUTO-UPGRADE ===
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
      nodeOSUpgradeChannel: 'NodeImage'
    }

    // === SYSTEM NODE POOL ===
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        vmSize: systemNodeVmSize
        count: systemNodeCount
        minCount: systemNodeCount
        maxCount: systemNodeCount + 2
        enableAutoScaling: true
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        osType: 'Linux'
        osSKU: 'AzureLinux' // Azure Linux for better security and performance
        vnetSubnetID: aksSubnetId
        maxPods: 110 // Azure CNI Overlay supports higher pod density
        availabilityZones: ['1', '2', '3']
        enableNodePublicIP: false
        nodeTaints: ['CriticalAddonsOnly=true:NoSchedule']
        upgradeSettings: {
          maxSurge: '33%'
        }
        tags: tags
      }
    ]

    // === STORAGE ===
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
      blobCSIDriver: {
        enabled: false // Enable if blob storage needed
      }
    }
  }
}

// === USER NODE POOL ===

@description('User node pool for application workloads')
resource userNodePool 'Microsoft.ContainerService/managedClusters/agentPools@2024-09-01' = {
  parent: aks
  name: 'user'
  properties: {
    mode: 'User'
    vmSize: userNodeVmSize
    count: userNodeCount
    minCount: 1
    maxCount: userNodeCount + 5
    enableAutoScaling: true
    osDiskSizeGB: 128
    osDiskType: 'Managed'
    osType: 'Linux'
    osSKU: 'AzureLinux'
    vnetSubnetID: aksSubnetId
    maxPods: 110
    availabilityZones: ['1', '2', '3']
    enableNodePublicIP: false
    upgradeSettings: {
      maxSurge: '33%'
    }
    tags: tags
  }
}

// === DIAGNOSTIC SETTINGS ===

@description('Diagnostic settings for AKS cluster')
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${aksName}'
  scope: aks
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

@description('AKS cluster resource ID')
output aksId string = aks.id

@description('AKS cluster name')
output aksName string = aks.name

@description('AKS cluster FQDN (private)')
output aksFqdn string = aks.properties.privateFQDN

@description('AKS kubelet identity object ID')
output kubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId

@description('AKS kubelet identity client ID')
output kubeletIdentityClientId string = aks.properties.identityProfile.kubeletidentity.clientId

@description('AKS cluster identity principal ID')
output aksIdentityPrincipalId string = aks.identity.principalId

@description('AKS OIDC issuer URL')
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL

@description('Key Vault Secrets Provider identity client ID')
output keyVaultSecretsProviderClientId string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.clientId

@description('Key Vault Secrets Provider identity object ID')
output keyVaultSecretsProviderObjectId string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
