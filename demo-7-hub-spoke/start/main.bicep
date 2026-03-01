// ============================================================
// Demo 7: Hub & Spoke VNet - CAF/Landing Zone Pattern
// Start File - Complete the implementation using GitHub Copilot
//
// Goal: Create a hub and spoke network topology following:
//   - Azure Cloud Adoption Framework (CAF) naming conventions
//   - Azure Landing Zone architecture patterns
//   - Security best practices (Firewall, Bastion, UDR, NSGs)
//
// Architecture to build:
//   Hub VNet (10.0.0.0/16)
//   ├── AzureFirewallSubnet    10.0.0.0/26  → Azure Firewall Premium
//   ├── AzureBastionSubnet     10.0.1.0/26  → Azure Bastion Standard
//   ├── GatewaySubnet          10.0.2.0/27  → VPN/ER Gateway ready
//   └── snet-shared            10.0.3.0/24  → Shared services
//
//   Spoke: Identity (10.1.0.0/16)
//   └── snet-identity          10.1.0.0/24
//
//   Spoke: Workload (10.2.0.0/16)
//   ├── snet-workload          10.2.0.0/24
//   └── snet-workload-data     10.2.1.0/24
//
// Modules to create (in completed/modules/):
//   - hub-network.bicep   : Hub VNet, subnets, NSGs
//   - spoke-network.bicep : Reusable spoke VNet module
//   - firewall.bicep      : Azure Firewall Premium + Policy
//   - bastion.bicep       : Azure Bastion Standard
//   - route-table.bicep   : UDR to route spoke traffic via Firewall
//   - peering.bicep       : Bidirectional VNet peering
//   - monitoring.bicep    : Log Analytics workspace
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===
// TODO: Add parameters for location, environmentName, locationCode, logRetentionDays

// === VARIABLES ===
// TODO: Add tags variable following CAF conventions

// === MODULES ===

// TODO: Deploy monitoring (Log Analytics workspace)

// TODO: Deploy hub network (Hub VNet with subnets for Firewall, Bastion, Gateway, Shared)

// TODO: Deploy Azure Firewall Premium with policy and rules

// TODO: Deploy Azure Bastion Standard for secure VM access

// TODO: Deploy identity spoke VNet (10.1.0.0/16)

// TODO: Deploy workload spoke VNet (10.2.0.0/16) with app and data subnets

// TODO: Deploy route tables (UDR) for each spoke pointing to Firewall private IP

// TODO: Deploy VNet peering between hub and each spoke (bidirectional)

// === OUTPUTS ===
// TODO: Output hub VNet ID, spoke VNet IDs, firewall IP, bastion name, Log Analytics ID
