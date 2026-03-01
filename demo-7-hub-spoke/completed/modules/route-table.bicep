// ============================================================
// Module: Route Table (UDR)
// Hub & Spoke VNet - User-Defined Routes to force traffic through Firewall
// Applied to spoke subnets to inspect all egress traffic
// ============================================================

@description('Azure region for all resources')
param location string

@description('Route table purpose/identifier (matches spoke name)')
param routeTablePurpose string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Azure Firewall private IP address used as the next hop for all internet-bound traffic')
param firewallPrivateIp string

@description('Resource tags')
param tags object

// === VARIABLES ===

var routeTableName = 'rt-${routeTablePurpose}-${environmentName}'

// === ROUTE TABLE ===

@description('Route table with default route to Azure Firewall for all spoke traffic')
resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true // Prevent on-premises routes from overriding UDR
    routes: [
      {
        name: 'DefaultRouteToFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0' // All traffic
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp // Route through Azure Firewall
        }
      }
      {
        name: 'RouteToHubVnet'
        properties: {
          addressPrefix: '10.0.0.0/16' // Hub VNet CIDR
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp // Inspect inter-VNet traffic too
        }
      }
    ]
  }
}

// === OUTPUTS ===

@description('Route table resource ID')
output routeTableId string = routeTable.id

@description('Route table name')
output routeTableName string = routeTable.name
