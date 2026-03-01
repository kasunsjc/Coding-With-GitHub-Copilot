// ============================================================
// Module: RBAC Role Assignments
// Enterprise Private AKS - Azure Role Assignments
// ============================================================

@description('AKS cluster resource ID')
param aksId string

@description('AKS kubelet identity object ID')
param kubeletIdentityObjectId string

@description('AKS cluster identity principal ID')
param aksIdentityPrincipalId string

@description('Key Vault Secrets Provider identity object ID')
param keyVaultSecretsProviderObjectId string

@description('Container Registry resource ID')
param acrId string

@description('Key Vault resource ID')
param keyVaultId string

@description('Virtual network resource ID')
param vnetId string

@description('Jump box VM managed identity principal ID')
param jumpboxPrincipalId string

@description('Entra ID group object ID for AKS cluster admins')
param aksAdminGroupObjectId string

// === BUILT-IN ROLE DEFINITION IDs ===
var roleDefinitions = {
  acrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  aksClusterAdmin: '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8'
  aksClusterUserRole: '4abbcc35-e782-43d8-92c5-2d3f1bd2253f'
}

// === ACR PULL FOR KUBELET IDENTITY ===

@description('Allow AKS kubelet identity to pull images from ACR')
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, kubeletIdentityObjectId, roleDefinitions.acrPull)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.acrPull)
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

// === KEY VAULT SECRETS USER FOR CSI DRIVER ===

@description('Allow Key Vault Secrets Provider to read secrets')
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, keyVaultSecretsProviderObjectId, roleDefinitions.keyVaultSecretsUser)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.keyVaultSecretsUser)
    principalId: keyVaultSecretsProviderObjectId
    principalType: 'ServicePrincipal'
  }
}

// === NETWORK CONTRIBUTOR FOR AKS ===

@description('Allow AKS cluster identity to manage network resources')
resource networkContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vnetId, aksIdentityPrincipalId, roleDefinitions.networkContributor)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.networkContributor)
    principalId: aksIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// === AKS CLUSTER USER ROLE FOR JUMP BOX ===

@description('Allow Jump Box managed identity to get AKS credentials')
resource aksClusterUserRoleForJumpbox 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksId, jumpboxPrincipalId, roleDefinitions.aksClusterUserRole)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.aksClusterUserRole)
    principalId: jumpboxPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// === AKS CLUSTER ADMIN FOR ENTRA GROUP ===

@description('Grant AKS Cluster Admin role to the specified Entra ID group')
resource aksClusterAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksId, aksAdminGroupObjectId, roleDefinitions.aksClusterAdmin)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.aksClusterAdmin)
    principalId: aksAdminGroupObjectId
    principalType: 'Group'
  }
}
