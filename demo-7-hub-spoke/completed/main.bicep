// ============================================================
// Demo 7: Hub & Spoke VNet - CAF/Landing Zone Pattern
// Main Orchestration Template
//
// Architecture:
//   Hub VNet (10.0.0.0/16)
//   ├── AzureFirewallSubnet    10.0.0.0/26  → Azure Firewall Premium
//   ├── AzureBastionSubnet     10.0.1.0/26  → Azure Bastion Standard
//   ├── GatewaySubnet          10.0.2.0/27  → (VPN/ER Gateway ready)
//   └── snet-shared            10.0.3.0/24  → Shared services
//
//   Spoke: Identity (10.1.0.0/16)
//   └── snet-identity          10.1.0.0/24  → Identity workloads
//
//   Spoke: Workload (10.2.0.0/16)
//   ├── snet-workload          10.2.0.0/24  → Application tier
//   └── snet-workload-data     10.2.1.0/24  → Data tier
//
// All spoke egress is routed through Azure Firewall via UDR.
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'prod'

@description('Short location code used for resource naming (e.g. aue, eus, weu)')
@maxLength(6)
param locationCode string

@description('Log retention in days for Log Analytics workspace')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 30

// === VARIABLES ===

var tags = {
  environment: environmentName
  architecture: 'hub-spoke'
  managedBy: 'bicep'
  framework: 'caf-landing-zone'
}

// === MODULES ===

// --- Monitoring (deployed first - other modules depend on Log Analytics ID) ---
@description('Deploy centralised Log Analytics workspace for all diagnostics')
module monitoring 'modules/monitoring.bicep' = {
  name: 'deploy-monitoring'
  params: {
    location: location
    environmentName: environmentName
    locationCode: locationCode
    retentionInDays: logRetentionDays
    tags: tags
  }
}

// --- Hub Network ---
@description('Deploy hub virtual network with all required subnets')
module hubNetwork 'modules/hub-network.bicep' = {
  name: 'deploy-hub-network'
  params: {
    location: location
    environmentName: environmentName
    locationCode: locationCode
    tags: tags
  }
}

// --- Azure Firewall ---
@description('Deploy Azure Firewall Premium for centralised traffic inspection and egress control')
module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    environmentName: environmentName
    locationCode: locationCode
    firewallSubnetId: hubNetwork.outputs.firewallSubnetId
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    tags: tags
  }
}

// --- Azure Bastion ---
@description('Deploy Azure Bastion for secure access to VMs in all spokes via hub')
module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    location: location
    environmentName: environmentName
    locationCode: locationCode
    bastionSubnetId: hubNetwork.outputs.bastionSubnetId
    logAnalyticsId: monitoring.outputs.logAnalyticsId
    tags: tags
  }
}

// --- Route Table: Identity Spoke ---
@description('Deploy UDR for identity spoke - route all traffic through Azure Firewall')
module identityRouteTable 'modules/route-table.bicep' = {
  name: 'deploy-rt-identity'
  params: {
    location: location
    routeTablePurpose: 'identity'
    environmentName: environmentName
    firewallPrivateIp: firewall.outputs.firewallPrivateIp
    tags: tags
  }
}

// --- Route Table: Workload Spoke ---
@description('Deploy UDR for workload spoke - route all traffic through Azure Firewall')
module workloadRouteTable 'modules/route-table.bicep' = {
  name: 'deploy-rt-workload'
  params: {
    location: location
    routeTablePurpose: 'workload'
    environmentName: environmentName
    firewallPrivateIp: firewall.outputs.firewallPrivateIp
    tags: tags
  }
}

// --- Identity Spoke Network ---
@description('Deploy identity spoke virtual network for identity/directory workloads')
module identitySpoke 'modules/spoke-network.bicep' = {
  name: 'deploy-identity-spoke'
  params: {
    location: location
    spokePurpose: 'identity'
    environmentName: environmentName
    locationCode: locationCode
    spokeVnetAddressPrefix: '10.1.0.0/16'
    workloadSubnetAddressPrefix: '10.1.0.0/24'
    routeTableId: identityRouteTable.outputs.routeTableId
    tags: tags
  }
}

// --- Workload Spoke Network ---
@description('Deploy workload spoke virtual network for application and data workloads')
module workloadSpoke 'modules/spoke-network.bicep' = {
  name: 'deploy-workload-spoke'
  params: {
    location: location
    spokePurpose: 'workload'
    environmentName: environmentName
    locationCode: locationCode
    spokeVnetAddressPrefix: '10.2.0.0/16'
    workloadSubnetAddressPrefix: '10.2.0.0/24'
    dataSubnetAddressPrefix: '10.2.1.0/24'
    routeTableId: workloadRouteTable.outputs.routeTableId
    tags: tags
  }
}

// --- VNet Peering: Hub <-> Identity Spoke ---
@description('Deploy bidirectional VNet peering between hub and identity spoke')
module identityPeering 'modules/peering.bicep' = {
  name: 'deploy-peering-identity'
  params: {
    hubVnetId: hubNetwork.outputs.hubVnetId
    hubVnetName: hubNetwork.outputs.hubVnetName
    spokeVnetId: identitySpoke.outputs.spokeVnetId
    spokeVnetName: identitySpoke.outputs.spokeVnetName
    spokePurpose: 'identity'
  }
}

// --- VNet Peering: Hub <-> Workload Spoke ---
@description('Deploy bidirectional VNet peering between hub and workload spoke')
module workloadPeering 'modules/peering.bicep' = {
  name: 'deploy-peering-workload'
  params: {
    hubVnetId: hubNetwork.outputs.hubVnetId
    hubVnetName: hubNetwork.outputs.hubVnetName
    spokeVnetId: workloadSpoke.outputs.spokeVnetId
    spokeVnetName: workloadSpoke.outputs.spokeVnetName
    spokePurpose: 'workload'
  }
}

// === OUTPUTS ===

@description('Hub virtual network resource ID')
output hubVnetId string = hubNetwork.outputs.hubVnetId

@description('Hub virtual network name')
output hubVnetName string = hubNetwork.outputs.hubVnetName

@description('Identity spoke virtual network resource ID')
output identitySpokeVnetId string = identitySpoke.outputs.spokeVnetId

@description('Identity spoke virtual network name')
output identitySpokeVnetName string = identitySpoke.outputs.spokeVnetName

@description('Workload spoke virtual network resource ID')
output workloadSpokeVnetId string = workloadSpoke.outputs.spokeVnetId

@description('Workload spoke virtual network name')
output workloadSpokeVnetName string = workloadSpoke.outputs.spokeVnetName

@description('Azure Firewall private IP address (next hop for UDR)')
output firewallPrivateIp string = firewall.outputs.firewallPrivateIp

@description('Azure Firewall public IP address')
output firewallPublicIp string = firewall.outputs.firewallPublicIp

@description('Azure Bastion name')
output bastionName string = bastion.outputs.bastionName

@description('Log Analytics workspace resource ID')
output logAnalyticsId string = monitoring.outputs.logAnalyticsId

@description('Log Analytics workspace customer ID')
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId

@description('Identity spoke route table resource ID')
output identityRouteTableId string = identityRouteTable.outputs.routeTableId

@description('Workload spoke route table resource ID')
output workloadRouteTableId string = workloadRouteTable.outputs.routeTableId
