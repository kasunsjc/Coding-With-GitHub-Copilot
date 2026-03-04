// ============================================================
// Demo 6: Enterprise AKS — COMPLETED REFERENCE
// ============================================================
// Private AKS cluster following Azure CAF naming conventions
// and Landing Zone patterns with Bastion host for secure access.
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===
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

@description('Kubernetes version for the AKS cluster')
param kubernetesVersion string = '1.30'

@description('Number of nodes in the AKS system node pool')
@minValue(1)
@maxValue(10)
param aksNodeCount int = 3

@description('Maximum number of nodes for AKS autoscaling')
@minValue(1)
@maxValue(20)
param aksMaxNodeCount int = 6

@description('VM size for the AKS system node pool')
param aksNodeVmSize string = 'Standard_D4s_v5'

@description('Admin username for the jump box VM')
param jumpBoxAdminUsername string

@description('Admin password for the jump box VM')
@secure()
param jumpBoxAdminPassword string

// === VARIABLES ===
var resourcePrefix = '${projectName}-${environmentName}'
var aksName = 'aks-${resourcePrefix}'
var vnetName = 'vnet-${resourcePrefix}'
var bastionName = 'bas-${resourcePrefix}'
var tags = {
  environment: environmentName
  project: projectName
  managedBy: 'bicep'
}

// === NETWORKING: NETWORK SECURITY GROUPS ===

@description('NSG for AKS nodes subnet — deny inbound from internet')
resource nsgAksNodes 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-aks-nodes-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'DenyAllInboundFromInternet'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

@description('NSG for jump box subnet — allow SSH from VNet only')
resource nsgJumpbox 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-jumpbox-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSHFromVNet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInboundFromInternet'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

@description('NSG for private endpoints subnet — deny all inbound from internet')
resource nsgPe 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-pe-${environmentName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'DenyAllInboundFromInternet'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// === NETWORKING: VIRTUAL NETWORK & SUBNETS ===

@description('Virtual network for the enterprise AKS Landing Zone')
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
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
        name: 'snet-aks-nodes'
        properties: {
          addressPrefix: '10.0.0.0/22'
          networkSecurityGroup: {
            id: nsgAksNodes.id
          }
        }
      }
      {
        name: 'snet-jumpbox'
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: nsgJumpbox.id
          }
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: {
            id: nsgPe.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.255.0/26'
        }
      }
    ]
  }
}

// === MONITORING ===

@description('Log Analytics workspace for Container Insights and diagnostics')
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${projectName}-${environmentName}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// === AKS CLUSTER ===

@description('Private AKS cluster with Azure CNI and Defender for Containers')
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-06-02-preview' = {
  name: aksName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${projectName}-${environmentName}'
    enableRBAC: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: aksNodeCount
        vmSize: aksNodeVmSize
        mode: 'System'
        osType: 'Linux'
        vnetSubnetID: vnet.properties.subnets[0].id
        enableAutoScaling: true
        minCount: 1
        maxCount: aksMaxNodeCount
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
    }
    securityProfile: {
      defender: {
        securityMonitoring: {
          enabled: true
        }
        logAnalyticsWorkspaceResourceId: logAnalytics.id
      }
    }
  }
}

// === CONTAINER REGISTRY ===

@description('Premium ACR with private endpoint support')
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: 'cr${replace(projectName, '-', '')}${environmentName}'
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
  }
}

@description('Private endpoint for ACR')
resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'pe-acr-${environmentName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: vnet.properties.subnets[2].id
    }
    privateLinkServiceConnections: [
      {
        name: 'acr-connection'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

@description('Private DNS zone for ACR')
resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: tags
}

@description('Link ACR private DNS zone to VNet')
resource acrDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: acrPrivateDnsZone
  name: 'acr-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

@description('DNS zone group for ACR private endpoint')
resource acrDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: acrPrivateEndpoint
  name: 'acr-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acr-config'
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
}

// === ACR PULL ROLE ASSIGNMENT ===

@description('Grant AKS kubelet identity AcrPull role on Container Registry')
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, aksCluster.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

// === BASTION HOST ===

@description('Public IP for Azure Bastion')
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-${bastionName}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

@description('Azure Bastion host for secure jump box access')
resource bastionHost 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'bastion-ip-config'
        properties: {
          subnet: {
            id: vnet.properties.subnets[3].id
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// === JUMP BOX VM ===

@description('NIC for the jump box VM — no public IP')
resource jumpBoxNic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'nic-vm-jumpbox-${environmentName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

@description('Jump box VM — accessible only via Azure Bastion')
resource jumpBoxVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-jumpbox-${environmentName}'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: jumpBoxAdminUsername
      adminPassword: jumpBoxAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpBoxNic.id
        }
      ]
    }
  }
}

// === OUTPUTS ===
@description('Name of the AKS cluster')
output aksClusterName string = aksCluster.name

@description('Private FQDN for the AKS API server')
output aksPrivateFqdn string = aksCluster.properties.privateFQDN

@description('Azure Bastion host name')
output bastionHostName string = bastionHost.name

@description('ACR login server')
output acrLoginServer string = containerRegistry.properties.loginServer

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.id
