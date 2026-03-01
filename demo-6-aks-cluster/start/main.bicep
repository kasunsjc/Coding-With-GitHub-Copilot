// ============================================================
// Demo 6: Enterprise Private AKS Cluster
// STARTING TEMPLATE - Complete the TODOs with Copilot
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===
// TODO: Add parameters for:
// - location (default to resourceGroup().location)
// - environmentName (allowed: dev, staging, prod)
// - projectName (max 12 characters)
// - aksAdminGroupObjectId (Entra ID group for AKS admins)
// - jumpBoxAdminUsername
// - jumpBoxAdminPassword (@secure())
// - kubernetesVersion (default: 1.29)
// - systemNodeCount (1-10)
// - userNodeCount (1-100)
// - nodeVmSize (default: Standard_D4s_v5)

// === VARIABLES ===
// TODO: Create tags object with environment, project, managedBy

// === MODULES ===

// TODO: Deploy networking module
// - Virtual Network with subnets for AKS, private endpoints, bastion, jumpbox
// - Network Security Groups for each subnet

// TODO: Deploy monitoring module
// - Log Analytics Workspace
// - Container Insights solution

// TODO: Deploy private DNS zones module
// - DNS zones for ACR, Key Vault, and AKS API server
// - VNet links

// TODO: Deploy Key Vault module
// - Key Vault with RBAC authorization
// - Private endpoint
// - Diagnostic settings

// TODO: Deploy ACR module
// - Premium SKU (required for private endpoint)
// - Public network access disabled
// - Private endpoint

// TODO: Deploy Bastion module
// - Standard SKU for tunneling support
// - Public IP

// TODO: Deploy Jump Box module
// - Linux VM with managed identity
// - Cloud-init to install kubectl, helm, az cli
// - No public IP

// TODO: Deploy AKS module
// - Private cluster (no public API)
// - Azure CNI Overlay network plugin
// - System node pool with CriticalAddonsOnly taint
// - User node pool for workloads
// - Entra ID + Azure RBAC
// - Disable local accounts
// - Container Insights addon
// - Key Vault Secrets Provider addon
// - Azure Policy addon
// - Defender for Containers

// TODO: Deploy RBAC module
// - ACR Pull for kubelet identity
// - Key Vault Secrets User for CSI driver
// - Network Contributor for AKS
// - AKS Cluster Admin for Entra group

// === OUTPUTS ===
// TODO: Output:
// - AKS cluster name
// - AKS private FQDN
// - ACR login server
// - Key Vault URI
// - Jump box VM name
// - Connection instructions
