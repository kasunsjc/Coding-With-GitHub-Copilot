// ============================================================
// Demo 6: Enterprise Private AKS Cluster
// Parameter File
// ============================================================

using 'main.bicep'

// === REQUIRED PARAMETERS ===

// Project name - used for all resource naming (max 12 chars)
param projectName = 'myapp'

// Entra ID group object ID for AKS cluster administrators
// Get this from Azure Portal > Entra ID > Groups > Your Group > Object ID
param aksAdminGroupObjectId = '<REPLACE-WITH-ENTRA-GROUP-OBJECT-ID>'

// Jump box VM credentials
param jumpBoxAdminUsername = 'azureuser'
param jumpBoxAdminPassword = '<REPLACE-WITH-SECURE-PASSWORD>'

// === OPTIONAL PARAMETERS (with defaults) ===

// Environment - dev, staging, or prod
param environmentName = 'prod'

// Kubernetes version
param kubernetesVersion = '1.29'

// Node pool configuration
param systemNodeCount = 2
param userNodeCount = 3
param nodeVmSize = 'Standard_D4s_v5'

// Jump box size
param jumpBoxVmSize = 'Standard_B2ms'

// Log retention
param logRetentionDays = 30
