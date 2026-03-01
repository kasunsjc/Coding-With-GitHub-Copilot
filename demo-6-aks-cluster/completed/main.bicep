// ============================================================
// Demo 6: Enterprise Private AKS Cluster
// Main Orchestration Template
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'prod'

@description('Project name used for resource naming (max 12 characters)')
@maxLength(12)
param projectName string

@description('Object ID of the Entra ID group for AKS cluster administrators')
param aksAdminGroupObjectId string

@description('Admin username for the jump box VM')
param jumpBoxAdminUsername string

@description('Admin password for the jump box VM')
@secure()
param jumpBoxAdminPassword string

@description('Kubernetes version for AKS cluster')
param kubernetesVersion string = '1.29'

@description('Number of nodes in the system node pool')
@minValue(1)
@maxValue(10)
param systemNodeCount int = 2

@description('Number of nodes in the user node pool')
@minValue(1)
@maxValue(100)
param userNodeCount int = 3

@description('VM size for AKS nodes')
param nodeVmSize string = 'Standard_D4s_v5'

@description('VM size for jump box')
param jumpBoxVmSize string = 'Standard_B2ms'

@description('Log retention in days')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 30

// === VARIABLES ===

var tags = {
  environment: environmentName
  project: projectName
  managedBy: 'bicep'
}

// === MODULES ===

// --- Networking ---
@description('Deploy virtual network and network security groups')
module networking 'modules/networking.bicep' = {
  name: 'deploy-networking'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
  }
}

// --- Monitoring ---
@description('Deploy Log Analytics workspace and Container Insights solution')
module monitoring 'modules/monitoring.bicep' = {
  name: 'deploy-monitoring'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    retentionInDays: logRetentionDays
  }
}

// --- Private DNS Zones ---
@description('Deploy private DNS zones for private endpoints')
module privateDns 'modules/private-dns.bicep' = {
  name: 'deploy-private-dns'
  params: {
    vnetId: networking.outputs.vnetId
    tags: tags
    location: location
  }
}

// --- Key Vault ---
@description('Deploy Key Vault with private endpoint')
module keyVault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    privateEndpointsSubnetId: networking.outputs.privateEndpointsSubnetId
    keyVaultDnsZoneId: privateDns.outputs.keyVaultDnsZoneId
    logAnalyticsId: monitoring.outputs.logAnalyticsId
  }
}

// --- Container Registry ---
@description('Deploy Azure Container Registry with private endpoint')
module acr 'modules/acr.bicep' = {
  name: 'deploy-acr'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    privateEndpointsSubnetId: networking.outputs.privateEndpointsSubnetId
    acrDnsZoneId: privateDns.outputs.acrDnsZoneId
    logAnalyticsId: monitoring.outputs.logAnalyticsId
  }
}

// --- Azure Bastion ---
@description('Deploy Azure Bastion for secure VM access')
module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    bastionSubnetId: networking.outputs.bastionSubnetId
    logAnalyticsId: monitoring.outputs.logAnalyticsId
  }
}

// --- Jump Box VM ---
@description('Deploy jump box VM for AKS management')
module jumpbox 'modules/jumpbox.bicep' = {
  name: 'deploy-jumpbox'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    jumpboxSubnetId: networking.outputs.jumpboxSubnetId
    adminUsername: jumpBoxAdminUsername
    adminPassword: jumpBoxAdminPassword
    vmSize: jumpBoxVmSize
  }
}

// --- AKS Cluster ---
@description('Deploy private AKS cluster')
module aks 'modules/aks.bicep' = {
  name: 'deploy-aks'
  params: {
    location: location
    projectName: projectName
    environmentName: environmentName
    tags: tags
    aksSubnetId: networking.outputs.aksSubnetId
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    kubernetesVersion: kubernetesVersion
    systemNodeVmSize: nodeVmSize
    systemNodeCount: systemNodeCount
    userNodeVmSize: nodeVmSize
    userNodeCount: userNodeCount
    aksAdminGroupObjectId: aksAdminGroupObjectId
  }
}

// --- RBAC Role Assignments ---
@description('Deploy role assignments for AKS, ACR, Key Vault')
module rbac 'modules/rbac.bicep' = {
  name: 'deploy-rbac'
  params: {
    aksId: aks.outputs.aksId
    kubeletIdentityObjectId: aks.outputs.kubeletIdentityObjectId
    aksIdentityPrincipalId: aks.outputs.aksIdentityPrincipalId
    keyVaultCsiDriverObjectId: aks.outputs.keyVaultSecretsProviderObjectId
    acrId: acr.outputs.acrId
    keyVaultId: keyVault.outputs.keyVaultId
    vnetId: networking.outputs.vnetId
    jumpboxPrincipalId: jumpbox.outputs.vmPrincipalId
    aksAdminGroupObjectId: aksAdminGroupObjectId
  }
}

// === OUTPUTS ===

@description('AKS cluster name')
output aksClusterName string = aks.outputs.aksName

@description('AKS private FQDN (use from jump box)')
output aksPrivateFqdn string = aks.outputs.aksFqdn

@description('Container Registry login server')
output acrLoginServer string = acr.outputs.acrLoginServer

@description('Key Vault URI')
output keyVaultUri string = keyVault.outputs.keyVaultUri

@description('Jump box VM name (connect via Bastion)')
output jumpBoxVmName string = jumpbox.outputs.vmName

@description('Azure Bastion name')
output bastionName string = bastion.outputs.bastionName

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId

@description('Instructions to connect to AKS')
output connectionInstructions string = '''
To connect to the private AKS cluster:
1. Go to Azure Portal > Virtual Machines > ${jumpbox.outputs.vmName}
2. Click "Connect" > "Bastion"
3. Enter your credentials
4. Run: az login --identity
5. Run: az aks get-credentials --resource-group ${resourceGroup().name} --name ${aks.outputs.aksName}
6. Run: kubectl get nodes
'''
