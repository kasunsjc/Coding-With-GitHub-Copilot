// ============================================================
// Module: VNet Peering
// Hub & Spoke VNet - Bidirectional VNet peering between Hub and Spoke
// Creates both hub-to-spoke and spoke-to-hub peering connections
// ============================================================

@description('Hub virtual network resource ID')
param hubVnetId string

@description('Hub virtual network name')
param hubVnetName string

@description('Spoke virtual network resource ID')
param spokeVnetId string

@description('Spoke virtual network name')
param spokeVnetName string

@description('Spoke purpose identifier (used in peering resource names)')
param spokePurpose string

// === HUB TO SPOKE PEERING ===

@description('Peering from hub VNet to spoke VNet - allows hub to reach spoke resources')
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${hubVnetName}/peer-hub-to-${spokePurpose}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true // Allow forwarded traffic from spoke through hub
    allowGatewayTransit: true // Allow spoke to use hub's VPN/ER gateway
    useRemoteGateways: false
  }
}

// === SPOKE TO HUB PEERING ===

@description('Peering from spoke VNet to hub VNet - allows spoke to route through hub firewall')
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${spokeVnetName}/peer-${spokePurpose}-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true // Required for traffic to flow through Azure Firewall
    allowGatewayTransit: false
    useRemoteGateways: false // Set to true if using hub's VPN/ER gateway
  }
}

// === OUTPUTS ===

@description('Hub-to-spoke peering resource ID')
output hubToSpokePeeringId string = hubToSpokePeering.id

@description('Spoke-to-hub peering resource ID')
output spokeToHubPeeringId string = spokeToHubPeering.id
