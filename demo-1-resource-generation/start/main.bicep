// ============================================================
// Demo 1: Azure Resource Generation from Comments
// ============================================================
// Instructions: Place your cursor after each comment block
// and let GitHub Copilot generate the Bicep resource definition.
// Press Tab to accept suggestions.
// ============================================================

targetScope = 'resourceGroup'

// --- Parameters ---
// Create a parameter for the Azure region/location with a default of the resource group location



// Create a parameter for the environment name (dev, staging, prod) with allowed values decorator


// Create a parameter for a project name string with a max length of 12 characters


// --- Resource 1: Storage Account ---
// Create an Azure Storage Account with:
// - Name: a unique name using the project name and environment
// - SKU: Standard_LRS
// - Kind: StorageV2
// - Minimum TLS version: TLS 1_2
// - HTTPS traffic only
// - Blob public access disabled


// --- Resource 2: Virtual Network ---
// Create an Azure Virtual Network with:
// - Address space: 10.0.0.0/16
// - Two subnets: "app-subnet" (10.0.1.0/24) and "data-subnet" (10.0.2.0/24)
// - Tags for environment and project


// --- Resource 3: App Service Plan ---
// Create a Linux App Service Plan with:
// - SKU: P1v3 tier
// - Reserved: true (for Linux)
// - Tags for environment and project


// --- Resource 4: Key Vault ---
// Create an Azure Key Vault with:
// - SKU: standard
// - Soft delete enabled with 90 day retention
// - Purge protection enabled
// - RBAC authorization enabled (no access policies)
// - Network ACLs defaulting to deny


// --- Resource 5: SQL Server and Database ---
// Create an Azure SQL Server with:
// - Azure AD only authentication enabled
// - Minimum TLS version 1.2
// Then create a SQL Database on that server with:
// - SKU: S1 (Standard tier)
// - Max size: 2GB


// --- Outputs ---
// Output the storage account name, key vault URI, and SQL server FQDN
