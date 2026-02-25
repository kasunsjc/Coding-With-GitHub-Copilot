# Cheat Sheet — Bicep + GitHub Copilot

> Print this or keep it open on a second screen during the demo

---

## Copilot Keyboard Shortcuts (macOS)

| Action | Shortcut |
|--------|----------|
| Accept suggestion | `Tab` |
| Dismiss suggestion | `Esc` |
| Next suggestion | `Option + ]` |
| Previous suggestion | `Option + [` |
| Open Copilot Chat | `Cmd + Shift + I` |
| Inline Chat | `Cmd + I` |
| Toggle Copilot on/off | Click status bar icon |

## Copilot Chat Commands

| Command | Use For |
|---------|---------|
| `/explain` | Explain selected Bicep code |
| `/fix` | Fix linter warnings or errors |
| `/doc` | Add descriptions/documentation |
| `/tests` | Generate test scenarios |
| `@workspace` | Search across project files |
| `#file:name.bicep` | Reference specific file as context |
| `#selection` | Reference selected code |

---

## Bicep CLI Quick Reference

```bash
# Build (validate)
az bicep build --file main.bicep

# Decompile ARM → Bicep
az bicep decompile --file template.json

# Preview changes
az deployment group what-if \
  --resource-group myRG \
  --template-file main.bicep \
  --parameters main.bicepparam

# Deploy
az deployment group create \
  --resource-group myRG \
  --template-file main.bicep \
  --parameters main.bicepparam

# Check Bicep version
az bicep version

# Upgrade Bicep
az bicep upgrade
```

---

## Bicep Syntax Quick Reference

### Parameters with Decorators
```bicep
@description('The deployment environment')
@allowed(['dev', 'staging', 'prod'])
param environment string

@secure()
@description('Admin password')
param adminPassword string

@minLength(3)
@maxLength(12)
param projectName string

@minValue(1)
@maxValue(10)
param instanceCount int = 1
```

### Resource Declaration
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${project}${env}${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_GRS' }
  kind: 'StorageV2'
  properties: { ... }
  tags: { ... }
}
```

### Module Call
```bicep
module networking 'modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    location: location
    environment: environment
  }
}
```

### Outputs
```bicep
output storageId string = storageAccount.id
output storageName string = storageAccount.name
```

### Conditional Deployment
```bicep
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = if (deployKeyVault) {
  name: 'kv-${project}'
  ...
}
```

### Loops
```bicep
param subnets array = [
  { name: 'snet-app', prefix: '10.0.1.0/24' }
  { name: 'snet-data', prefix: '10.0.2.0/24' }
]

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-01-01' = [
  for subnet in subnets: {
    name: 'nsg-${subnet.name}'
    location: location
  }
]
```

### Existing Resource Reference
```bicep
resource existingVnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: 'vnet-prod'
}
```

### Parameter File (.bicepparam)
```bicep
using 'main.bicep'

param environment = 'prod'
param projectName = 'myapp'
param location = 'australiaeast'
```

---

## Azure CAF Naming Abbreviations

| Resource | Abbreviation |
|----------|-------------|
| Resource Group | `rg-` |
| Virtual Network | `vnet-` |
| Subnet | `snet-` |
| Network Security Group | `nsg-` |
| Public IP | `pip-` |
| Storage Account | `st` (no hyphen) |
| Key Vault | `kv-` |
| SQL Server | `sql-` |
| SQL Database | `sqldb-` |
| App Service Plan | `asp-` |
| Web App | `app-` |
| Function App | `func-` |
| Log Analytics | `log-` |
| App Insights | `appi-` |
| Container Registry | `acr` (no hyphen) |
| Managed Identity | `id-` |

---

## Effective Prompt Patterns for Bicep

### Resource Generation
```
// Create an Azure [Resource] with [SKU/tier],
// [security settings], [networking settings],
// tagged with environment and project.
// Name: {abbreviation}-{project}-{env}-{unique}
```

### Conversion
```
Convert this ARM template to Bicep with modern best practices:
modules, decorators, strong typing, and proper naming.
```

### Refactoring
```
Refactor this monolith Bicep into modules:
networking, compute, data, monitoring.
Each module should have typed parameters and outputs.
```

### Security Review
```
Review this Bicep for security issues:
check for hardcoded secrets, missing TLS,
public access, overly permissive network rules.
```

---

## Emergency Backup Commands

```bash
# If Copilot stops working
# 1. Check status: github.com/status
# 2. Restart extension: Cmd+Shift+P → "Reload Window"
# 3. Sign out/in: Cmd+Shift+P → "GitHub Copilot: Sign Out"

# If Bicep extension has issues
az bicep build --file main.bicep  # Verify CLI works
# Cmd+Shift+P → "Bicep: Restart Language Server"
```
