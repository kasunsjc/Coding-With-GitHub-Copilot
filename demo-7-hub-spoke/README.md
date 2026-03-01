# Demo 7: Hub & Spoke VNet — CAF / Landing Zone Pattern

This demo shows how to use GitHub Copilot to build an **enterprise hub and spoke network topology** in Azure using Bicep, following the [Azure Cloud Adoption Framework (CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/) and [Azure Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/) architecture patterns.

---

## Architecture Overview

```
Hub VNet (10.0.0.0/16)
├── AzureFirewallSubnet   10.0.0.0/26  → Azure Firewall Premium (centralised egress + inspection)
├── AzureBastionSubnet    10.0.1.0/26  → Azure Bastion Standard (secure VM access)
├── GatewaySubnet         10.0.2.0/27  → VPN/ExpressRoute Gateway ready
└── snet-shared           10.0.3.0/24  → Shared services (DNS, management)

Spoke: Identity (10.1.0.0/16)
└── snet-identity-prod    10.1.0.0/24  → Identity / directory workloads

Spoke: Workload (10.2.0.0/16)
├── snet-workload-prod    10.2.0.0/24  → Application tier
└── snet-workload-data-prod 10.2.1.0/24 → Data tier
```

All spoke VNets are peered to the hub. All spoke egress traffic is routed through Azure Firewall via User-Defined Routes (UDR).

---

## CAF Naming Conventions Used

| Resource | Name Pattern | Example |
|---|---|---|
| Hub VNet | `vnet-hub-<env>-<loc>` | `vnet-hub-prod-aue` |
| Spoke VNet | `vnet-spoke-<purpose>-<env>-<loc>` | `vnet-spoke-workload-prod-aue` |
| Azure Firewall | `afw-hub-<env>-<loc>` | `afw-hub-prod-aue` |
| Firewall Policy | `afwp-hub-<env>-<loc>` | `afwp-hub-prod-aue` |
| Azure Bastion | `bas-hub-<env>-<loc>` | `bas-hub-prod-aue` |
| Route Table | `rt-<purpose>-<env>` | `rt-workload-prod` |
| NSG | `nsg-<purpose>-<env>` | `nsg-workload-prod` |
| Log Analytics | `log-hub-<env>-<loc>` | `log-hub-prod-aue` |
| Public IP | `pip-<resource>-hub-<env>-<loc>` | `pip-afw-hub-prod-aue` |

---

## Modules

| Module | Purpose |
|---|---|
| `hub-network.bicep` | Hub VNet with Firewall, Bastion, Gateway, and Shared subnets + NSG |
| `spoke-network.bicep` | Reusable spoke VNet with workload and optional data subnets + NSGs |
| `firewall.bicep` | Azure Firewall Premium with policy, IDPS, DNS proxy, and default rules |
| `bastion.bicep` | Azure Bastion Standard with tunneling and IP connect enabled |
| `route-table.bicep` | UDR with default route pointing to Azure Firewall private IP |
| `peering.bicep` | Bidirectional VNet peering (hub→spoke and spoke→hub) |
| `monitoring.bicep` | Log Analytics workspace for centralised diagnostics |

---

## Prerequisites

- Azure CLI: `az --version` ≥ 2.50
- Bicep CLI: `az bicep install && az bicep version`
- Azure subscription with Contributor access
- Resource group created before deployment

---

## Deployment

### 1. Create a resource group

```bash
az group create \
  --name rg-hub-spoke-prod-aue \
  --location australiaeast
```

### 2. Update parameters

Edit `completed/main.bicepparam` with your values:

```bicep
param location = 'australiaeast'   // Your Azure region
param locationCode = 'aue'         // Short code for the region
param environmentName = 'prod'
param logRetentionDays = 30
```

### 3. Validate the template

```bash
az deployment group validate \
  --resource-group rg-hub-spoke-prod-aue \
  --template-file completed/main.bicep \
  --parameters completed/main.bicepparam
```

### 4. Deploy

```bash
az deployment group create \
  --resource-group rg-hub-spoke-prod-aue \
  --template-file completed/main.bicep \
  --parameters completed/main.bicepparam \
  --name hub-spoke-deployment
```

### 5. View outputs

```bash
az deployment group show \
  --resource-group rg-hub-spoke-prod-aue \
  --name hub-spoke-deployment \
  --query properties.outputs
```

---

## Security Features

| Feature | Implementation |
|---|---|
| **Centralised Egress** | All spoke traffic routed through Azure Firewall via UDR |
| **East-West Inspection** | Inter-spoke traffic also routed through Azure Firewall |
| **IDPS** | Azure Firewall Premium Intrusion Detection and Prevention |
| **DNS Proxy** | Firewall DNS proxy centralises DNS resolution for all spokes |
| **Threat Intelligence** | Firewall alerts on known malicious IPs/domains |
| **NSGs** | NSGs on all subnets with deny-all-inbound by default |
| **BGP Route Propagation** | Disabled on route tables (UDR takes priority) |
| **No Public IPs on VMs** | Access via Azure Bastion only |
| **Zone Redundancy** | Firewall, Bastion, and Public IPs deployed across 3 AZs |
| **Diagnostics** | All resources send logs to centralised Log Analytics |

---

## Adding More Spokes

To add a new spoke VNet, add a new module block in `main.bicep`:

```bicep
module dmzSpoke 'modules/spoke-network.bicep' = {
  name: 'deploy-dmz-spoke'
  params: {
    location: location
    spokePurpose: 'dmz'
    environmentName: environmentName
    locationCode: locationCode
    spokeVnetAddressPrefix: '10.3.0.0/16'
    workloadSubnetAddressPrefix: '10.3.0.0/24'
    tags: tags
  }
}
```

Then add the corresponding route table and peering modules.

---

## Demo Talking Points

1. **CAF naming** — Show how `locationCode` and `environmentName` flow through all resource names
2. **Reusable modules** — `spoke-network.bicep` is called twice (identity + workload) with different params
3. **Dependency chain** — Monitoring → Hub Network → Firewall → Route Tables → Peering
4. **Security by default** — NSG deny-all, UDR through Firewall, no public IPs on workloads
5. **Landing Zone alignment** — Hub provides shared services (Firewall, Bastion, Gateway) to all spokes
6. **Copilot suggestions** — Show Copilot auto-completing firewall rules, NSG rules, and peering config
