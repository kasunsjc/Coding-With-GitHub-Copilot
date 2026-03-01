// ============================================================
// Module: Private DNS Zones
// Enterprise Private AKS - DNS for Private Endpoints
// ============================================================

@description('Virtual network resource ID to link DNS zones')
param vnetId string

@description('Resource tags')
param tags object

@description('Azure region for AKS private DNS zone')
param location string

// === PRIVATE DNS ZONES ===

@description('Private DNS zone for Azure Container Registry')
resource dnsZoneAcr 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: tags
}

@description('Private DNS zone for Azure Key Vault')
resource dnsZoneKeyVault 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

@description('Private DNS zone for AKS API server')
resource dnsZoneAks 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.${location}.azmk8s.io'
  location: 'global'
  tags: tags
}

// === VNET LINKS ===

@description('Link ACR DNS zone to VNet')
resource vnetLinkAcr 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneAcr
  name: 'link-acr'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

@description('Link Key Vault DNS zone to VNet')
resource vnetLinkKeyVault 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneKeyVault
  name: 'link-keyvault'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

@description('Link AKS DNS zone to VNet')
resource vnetLinkAks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZoneAks
  name: 'link-aks'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// === OUTPUTS ===

@description('ACR private DNS zone resource ID')
output acrDnsZoneId string = dnsZoneAcr.id

@description('Key Vault private DNS zone resource ID')
output keyVaultDnsZoneId string = dnsZoneKeyVault.id

@description('AKS private DNS zone resource ID')
output aksDnsZoneId string = dnsZoneAks.id
