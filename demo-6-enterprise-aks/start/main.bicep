// ============================================================
// Demo 6: Enterprise AKS with Private Access & Azure Bastion
// ============================================================
// Instructions: Place your cursor after each section comment
// and let Copilot generate the Bicep resources.
// Follow Azure CAF naming conventions and Landing Zone patterns.
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===
// Create parameters for:
// - location (default: resource group location)
// - environmentName (allowed: dev, staging, prod)
// - projectName (max 12 chars)
// - kubernetesVersion (default: 1.30)
// - aksNodeCount (default: 3, min: 1, max: 10)
// - aksMaxNodeCount (default: 6, min: 1, max: 20) for autoscaling
// - aksNodeVmSize (default: Standard_D4s_v5)
// - jumpBoxAdminUsername (string, no literal default — use @secure for password)
// - jumpBoxAdminPassword (secure string, no default)


// === VARIABLES ===
// Create variables for:
// - resourcePrefix: combination of projectName and environmentName
// - aksName: CAF name aks-<projectName>-<env>
// - vnetName: CAF name vnet-<projectName>-<env>
// - bastionName: CAF name bas-<projectName>-<env>
// - tags: object with environment, project, and managedBy keys


// === NETWORKING: VIRTUAL NETWORK & SUBNETS ===
// Create a Virtual Network with address space 10.0.0.0/16 and four subnets:
// - snet-aks-nodes (10.0.0.0/22) for AKS node pools
// - snet-jumpbox (10.0.3.0/24) for the jump box VM
// - snet-pe (10.0.4.0/24) for private endpoints
// - AzureBastionSubnet (10.0.255.0/26) — must use this exact name for Bastion


// === NETWORKING: NETWORK SECURITY GROUPS ===
// Create NSGs for each subnet (except AzureBastionSubnet which has its own rules):
// - nsg-aks-nodes: allow outbound to internet, deny all inbound from internet
// - nsg-jumpbox: allow inbound SSH/RDP from VNet only, deny from internet
// - nsg-pe: deny all inbound from internet
// Attach each NSG to the corresponding subnet


// === MONITORING ===
// Create a Log Analytics Workspace with:
// - CAF name: log-<projectName>-<env>
// - PerGB2018 SKU
// - 30 day retention


// === AKS CLUSTER ===
// Create a private AKS cluster with:
// - CAF name: aks-<projectName>-<env>
// - Private cluster enabled (enablePrivateCluster: true)
// - API server access profile: no authorised IP ranges (private only)
// - Azure CNI networking plugin with the AKS nodes subnet
// - Service CIDR: 172.16.0.0/16, DNS service IP: 172.16.0.10
// - System-assigned managed identity
// - System node pool: 3 nodes, Standard_D4s_v5, mode System
// - Network policy: azure
// - Azure AD (Entra ID) RBAC integration with managed AAD enabled
// - OMS agent addon connected to the Log Analytics workspace
// - Microsoft Defender for Containers enabled
// - Kubernetes version from parameter


// === CONTAINER REGISTRY ===
// Create an Azure Container Registry with:
// - Premium SKU (required for private endpoint support)
// - Admin user disabled
// - Public network access disabled
// Create a private endpoint for ACR in the snet-pe subnet
// Create a private DNS zone for ACR and link to VNet


// === ACR PULL ROLE ASSIGNMENT ===
// Grant the AKS cluster's kubelet identity the AcrPull role on the Container Registry
// Role definition ID for AcrPull: 7f951dda-4ed3-4680-a7ca-43fe172d538d


// === BASTION HOST ===
// Create an Azure Bastion host with:
// - CAF name: bas-<projectName>-<env>
// - Standard SKU (supports native client / tunnelling)
// - Public IP with Standard SKU and Static allocation
// - Deployed into AzureBastionSubnet


// === JUMP BOX VM ===
// Create a Linux Virtual Machine as a jump box with:
// - CAF name: vm-jumpbox-<env>
// - Ubuntu 22.04 LTS image
// - Standard_B2s size (small management VM)
// - No public IP address — accessible only via Bastion
// - NIC connected to snet-jumpbox
// - Admin username from parameter (not hardcoded)
// - Password authentication from secure parameter


// === OUTPUTS ===
// Output the AKS cluster name, AKS private FQDN, Bastion name,
// Container Registry login server, and Log Analytics workspace ID
