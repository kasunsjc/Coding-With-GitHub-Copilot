# Demo 6: Enterprise Private AKS Cluster

## Overview

This demo creates a fully private, enterprise-grade Azure Kubernetes Service (AKS) cluster following **Azure Cloud Adoption Framework (CAF)** naming conventions and **Azure Landing Zone** security patterns.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Resource Group                                │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    Virtual Network                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │ │
│  │  │ AKS Subnet   │  │ PE Subnet    │  │ AzureBastionSubnet    │ │ │
│  │  │ 10.0.0.0/22  │  │ 10.0.4.0/24  │  │ 10.0.5.0/26           │ │ │
│  │  └──────────────┘  └──────────────┘  └───────────────────────┘ │ │
│  │  ┌──────────────┐                                              │ │
│  │  │ JumpBox      │                                              │ │
│  │  │ 10.0.6.0/24  │                                              │ │
│  │  └──────────────┘                                              │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────┐ │
│  │ Private AKS    │  │ ACR (Premium)  │  │ Key Vault              │ │
│  │ - System Pool  │  │ - Private EP   │  │ - Private EP           │ │
│  │ - User Pool    │  │ - No Public    │  │ - CSI Driver           │ │
│  │ - Entra RBAC   │  │                │  │                        │ │
│  └────────────────┘  └────────────────┘  └────────────────────────┘ │
│                                                                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────┐ │
│  │ Log Analytics  │  │ Azure Bastion  │  │ Jump Box VM            │ │
│  │ - Container    │  │ - Secure       │  │ - kubectl, helm        │ │
│  │   Insights     │  │   Access       │  │ - az cli               │ │
│  └────────────────┘  └────────────────┘  └────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Features

| Feature | Implementation |
|---------|---------------|
| **Private Cluster** | API server has no public IP; accessible only via private endpoint |
| **Network Plugin** | Azure CNI Overlay for scalable pod networking |
| **Authentication** | Microsoft Entra ID with Azure RBAC (no local accounts) |
| **Node Pools** | System pool (tainted) + User pool for workloads |
| **Container Registry** | Premium ACR with private endpoint |
| **Secrets Management** | Key Vault with CSI driver integration |
| **Access Method** | Azure Bastion + Jump Box VM |
| **Monitoring** | Container Insights + Log Analytics |

## Security Controls

- ✅ No public API server endpoint
- ✅ No public access to ACR or Key Vault
- ✅ Disabled local Kubernetes accounts
- ✅ Azure RBAC for Kubernetes authorization
- ✅ System-assigned managed identities (no service principals)
- ✅ Network Security Groups on all subnets
- ✅ TLS 1.2 minimum on all resources
- ✅ Diagnostic logs sent to Log Analytics
- ✅ Defender for Containers enabled

## Prerequisites

1. **Azure CLI** with Bicep extension installed
2. **Azure subscription** with the following providers registered:
   - `Microsoft.ContainerService`
   - `Microsoft.ContainerRegistry`
   - `Microsoft.KeyVault`
   - `Microsoft.Network`
   - `Microsoft.OperationalInsights`
3. **Entra ID Group** for AKS cluster administrators (Object ID required)
4. **Permissions**: Contributor + User Access Administrator on the subscription/resource group

## Deployment

### 1. Create Resource Group

```bash
az group create \
  --name rg-aks-prod-aue \
  --location australiaeast
```

### 2. Deploy the Infrastructure

```bash
az deployment group create \
  --resource-group rg-aks-prod-aue \
  --template-file completed/main.bicep \
  --parameters completed/main.bicepparam
```

### 3. Connect to the Cluster

Since this is a private cluster, you must connect via the Jump Box:

```bash
# 1. Connect to Jump Box via Azure Bastion (Azure Portal)
# 2. On the Jump Box, authenticate to Azure:
az login

# 3. Get AKS credentials:
az aks get-credentials \
  --resource-group rg-aks-prod-aue \
  --name aks-myapp-prod-aue

# 4. Verify connection:
kubectl get nodes
```

## File Structure

```
demo-6-aks-cluster/
├── README.md
├── bicepconfig.json
├── start/
│   └── main.bicep              # Skeleton for demo
└── completed/
    ├── main.bicep              # Main orchestration
    ├── main.bicepparam         # Parameter file
    └── modules/
        ├── networking.bicep    # VNet, subnets, NSGs
        ├── monitoring.bicep    # Log Analytics
        ├── private-dns.bicep   # Private DNS zones
        ├── keyvault.bicep      # Key Vault + PE
        ├── acr.bicep           # Container Registry + PE
        ├── bastion.bicep       # Azure Bastion
        ├── jumpbox.bicep       # Jump Box VM
        ├── aks.bicep           # AKS cluster
        └── rbac.bicep          # Role assignments
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `location` | Azure region | `resourceGroup().location` |
| `environmentName` | Environment (dev/staging/prod) | `prod` |
| `projectName` | Project name for naming | Required |
| `aksAdminGroupObjectId` | Entra ID group for AKS admins | Required |
| `jumpBoxAdminUsername` | Jump Box admin username | Required |
| `jumpBoxAdminPassword` | Jump Box admin password | Required (secure) |
| `kubernetesVersion` | AKS Kubernetes version | `1.29` |
| `systemNodeCount` | System pool node count | `2` |
| `userNodeCount` | User pool node count | `3` |
| `nodeVmSize` | VM size for nodes | `Standard_D4s_v5` |

## Cost Considerations

⚠️ **This is an enterprise-grade deployment with associated costs:**

- AKS cluster with multiple nodes
- Azure Bastion (Standard SKU)
- Premium ACR (required for private endpoint)
- Key Vault (Standard)
- Log Analytics workspace
- Jump Box VM

**Estimated monthly cost**: ~$800-1500 AUD depending on node count and region.

For demo purposes, consider:
- Reducing node counts
- Using smaller VM sizes
- Deleting resources after the demo

## Cleanup

```bash
az group delete --name rg-aks-prod-aue --yes --no-wait
```

## Demo Talking Points

1. **Why Private Cluster?** - Landing Zone requirement; no public API exposure
2. **Why Azure CNI Overlay?** - Scalable, no IP exhaustion, simpler than traditional CNI
3. **Why Entra ID + Azure RBAC?** - Unified identity, conditional access, no local accounts
4. **Why Bastion + Jump Box?** - Secure management plane access without VPN
5. **Why Key Vault CSI Driver?** - Native K8s secrets integration, no secrets in etcd
6. **Modular Design** - Reusable modules following Azure Verified Module patterns
