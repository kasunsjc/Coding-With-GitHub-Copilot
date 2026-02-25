# GitHub Copilot Instructions — Bicep / Infrastructure as Code

## Project Context
This repository contains Azure Bicep templates for provisioning and managing cloud infrastructure. All resources target Azure and follow our organization's cloud governance policies.

## Naming Conventions
- Use Azure CAF (Cloud Adoption Framework) abbreviations: `rg-`, `vnet-`, `snet-`, `kv-`, `st`, `sql-`, `app-`, `func-`, `log-`, `appi-`, `nsg-`, `pip-`, `acr`
- Follow pattern: `{abbreviation}-{project}-{environment}-{uniqueSuffix}`
- For storage accounts (no hyphens): `st{project}{env}{uniqueString}`
- Always use `uniqueString(resourceGroup().id)` for globally unique names

## Security Requirements (MANDATORY)
- **Never** hardcode secrets, passwords, or connection strings
- Always use `@secure()` decorator for sensitive parameters
- Use **managed identity** over connection strings wherever possible
- Enable **RBAC authorization** on Key Vault (not access policies)
- Set `minimumTlsVersion: 'TLS1_2'` on all resources that support it
- Set `publicNetworkAccess: 'Disabled'` for databases, Key Vault, and storage in production
- Disable blob public access: `allowBlobPublicAccess: false`
- Enable **purge protection** on Key Vault and storage soft delete
- Use **private endpoints** for data-plane access in production

## Bicep Best Practices
- Use **modules** for reusable components (networking, compute, data, monitoring)
- Always add `@description()` decorators to parameters and outputs
- Use `@allowed()` for parameters with known valid values (environments, SKUs)
- Use `@minLength()` / `@maxLength()` for string validation
- Prefer **parameter files** (`.bicepparam`) over inline defaults for environment configs
- Use `environment == 'prod'` conditionals for production-specific hardening
- Always include `tags` on every resource with at least: `environment`, `project`, `managedBy`

## Tagging Policy
Every resource MUST have these tags:
```bicep
tags: {
  environment: environment
  project: projectName
  managedBy: 'bicep'
  costCenter: costCenter
}
```

## Module Structure
```
modules/
  networking.bicep    — VNet, subnets, NSGs, route tables
  compute.bicep       — App Service, Function Apps, Container Apps
  data.bicep          — SQL, Storage, Cosmos DB
  monitoring.bicep    — Log Analytics, App Insights, alerts
  security.bicep      — Key Vault, RBAC assignments, private endpoints
```

## Code Style
- Use **camelCase** for resource symbolic names: `storageAccount`, `keyVault`
- Use descriptive resource names, not `res1` or `resource1`
- Group related resources together with comment headers
- Always output resource IDs and names that downstream modules may need
- Prefer `existing` keyword over `resourceId()` function for referencing existing resources

## Testing & Validation
- All Bicep files must pass `az bicep build` without errors
- Run `az deployment group what-if` before applying changes
- Use the linter rules defined in `bicepconfig.json`
