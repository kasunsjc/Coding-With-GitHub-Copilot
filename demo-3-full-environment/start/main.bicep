// ============================================================
// Demo 3: Build a Complete Azure Environment
// ============================================================
// Instructions: Place your cursor after each section comment
// and let Copilot generate the Bicep resources.
// ============================================================

targetScope = 'resourceGroup'

// === PARAMETERS ===
// Create parameters for:
// - location (default: resource group location)
// - environmentName (allowed: dev, staging, prod)
// - projectName (max 12 chars)
// - sqlAdminGroupObjectId (string, for AAD SQL admin)
// - alertEmailAddress (string, for action group notifications)


// === VARIABLES ===
// Create variables for:
// - resourcePrefix: combination of projectName and environmentName
// - tags: object with environment, project, and managedBy keys


// === NETWORKING ===
// Create a Virtual Network with address space 10.0.0.0/16 and three subnets:
// - app-subnet (10.0.1.0/24) with Microsoft.Web/serverFarms delegation
// - func-subnet (10.0.2.0/24) with Microsoft.Web/serverFarms delegation
// - pe-subnet (10.0.3.0/24) for private endpoints


// === MONITORING ===
// Create a Log Analytics Workspace with PerGB2018 SKU and 30 day retention
// Create Application Insights connected to the Log Analytics workspace


// === KEY VAULT ===
// Create a Key Vault with:
// - Standard SKU
// - RBAC authorization enabled
// - Soft delete with 90 days retention
// - Purge protection enabled
// - Network ACLs: default deny, bypass Azure services


// === STORAGE ===
// Create a Storage Account with:
// - Standard_LRS SKU, StorageV2 kind
// - TLS 1.2, HTTPS only, no public blob access
// - Blob services with delete retention of 7 days


// === SQL DATABASE ===
// Create an Azure SQL Server with:
// - Azure AD only authentication
// - TLS 1.2 minimum
// Create a SQL Database with S1 SKU


// === COMPUTE: APP SERVICE ===
// Create a Linux App Service Plan with P1v3 SKU
// Create a Web App with:
// - .NET 8.0 runtime
// - System-assigned managed identity
// - HTTPS only, FTPS disabled
// - VNet integrated with the app-subnet
// - App settings for App Insights connection string and Key Vault URI


// === COMPUTE: FUNCTION APP ===
// Create a Function App with:
// - .NET 8.0 isolated runtime
// - System-assigned managed identity
// - Connected to the storage account
// - VNet integrated with the func-subnet
// - App settings for App Insights and Key Vault


// === RBAC: KEY VAULT ACCESS ===
// Create role assignments to give the Web App and Function App
// managed identities the "Key Vault Secrets User" role on the Key Vault
// Role definition ID for Key Vault Secrets User: 4633458b-17de-408a-b874-0445c86b69e6


// === OUTPUTS ===
// Output the web app URL, function app URL, Key Vault URI, and SQL Server FQDN
