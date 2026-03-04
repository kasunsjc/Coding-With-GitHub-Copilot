# Demo 6: Enterprise AKS with Private Access and Azure Bastion

> **Duration:** ~8 minutes  
> **Goal:** Deploy a private, enterprise-grade AKS cluster following Azure CAF naming conventions and Landing Zone patterns, with Bastion host for secure cluster management

---

## What You'll Demonstrate

1. **Landing Zone networking** — Hub-style VNet with purpose-built subnets and NSGs
2. **Private AKS cluster** — API server with no public endpoint, Azure CNI networking
3. **Zero-trust access** — Azure Bastion + jump box VM as the only path to the cluster
4. **Enterprise monitoring** — Container Insights with Log Analytics and Defender for Containers
5. **Private container registry** — Premium ACR with private endpoint

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       Azure Resource Group                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                   Virtual Network (10.0.0.0/16)            │  │
│  │                                                            │  │
│  │  ┌──────────────────┐  ┌────────────────────────────────┐  │  │
│  │  │ AzureBastionSubnet│  │ snet-jumpbox                  │  │  │
│  │  │ 10.0.255.0/26    │  │ 10.0.3.0/24                   │  │  │
│  │  │                  │  │  ┌──────────┐                  │  │  │
│  │  │  ┌────────────┐  │  │  │ Jump Box │ ← kubectl access │  │  │
│  │  │  │  Bastion   │──┼──┼─▶│ VM       │                  │  │  │
│  │  │  └────────────┘  │  │  └──────────┘                  │  │  │
│  │  └──────────────────┘  └────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────┐  ┌─────────────────┐  │  │
│  │  │ snet-aks-nodes  10.0.0.0/22    │  │ snet-pe         │  │  │
│  │  │  ┌──────────────────────────┐  │  │ 10.0.4.0/24     │  │  │
│  │  │  │   Private AKS Cluster    │  │  │  ┌───────────┐  │  │  │
│  │  │  │   (System + User pools)  │  │  │  │ ACR PE    │  │  │  │
│  │  │  │   Private API Server     │  │  │  └───────────┘  │  │  │
│  │  │  └──────────────────────────┘  │  └─────────────────┘  │  │
│  │  └─────────────────────────────────┘                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ Log         │  │ Container        │  │ Microsoft Defender  │  │
│  │ Analytics   │◀─│ Insights         │  │ for Containers      │  │
│  └─────────────┘  └──────────────────┘  └─────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Live Demo Steps

### Step 1: Open the starter main.bicep

Open `start/main.bicep` — it contains section comments describing each component of the enterprise AKS architecture.

### Step 2: Generate resource by resource

1. **Parameters** — Copilot generates typed parameters with CAF-compliant decorators
2. **Networking** — VNet with AKS, Bastion, jump box, and private endpoint subnets plus NSGs
3. **Monitoring** — Log Analytics workspace for Container Insights
4. **AKS Cluster** — Private cluster with Azure CNI, managed identity, and Defender
5. **Container Registry** — Premium ACR with private endpoint
6. **Bastion + Jump Box** — Secure management path into the private cluster

### Step 3: Generate the parameter file

1. Open Copilot Chat
2. Ask: *"Generate a .bicepparam file for this Bicep template with sample dev environment values"*
3. Show the generated `main.bicepparam`

### Step 4: Validate

```bash
az bicep build --file main.bicep
az deployment group what-if --resource-group myRG --template-file main.bicep --parameters main.bicepparam
```

---

## Talking Points

- "We built an enterprise-grade, private AKS cluster with zero public exposure in under 10 minutes"
- "The API server is completely private — the only way in is through Bastion and the jump box"
- "Copilot applied CAF naming conventions automatically — `aks-`, `vnet-`, `snet-`, `nsg-` prefixes"
- "Network Security Groups are attached to every subnet — defence in depth"
- "Container Insights and Defender for Containers give us full observability and threat protection"
- "This follows the Azure Landing Zone pattern — separate subnets for nodes, management, and private endpoints"

---

## Reference

See `completed/` folder for the full working infrastructure.
