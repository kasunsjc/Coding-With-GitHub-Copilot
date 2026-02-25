# GitHub Copilot Custom Instructions

## Project Overview

This repository contains Azure Bicep demos for the session **"Coding with AI: How GitHub Copilot Transforms Developer Productivity"**. All infrastructure code targets Azure using Bicep (Azure's native IaC language).

---

## Language & Framework

- **Primary language:** Azure Bicep
- **Target platform:** Azure Resource Manager (ARM)
- **Tooling:** Azure CLI (`az`), Bicep CLI (`az bicep`)
- **Parameter files:** Use `.bicepparam` format (not JSON parameter files)

---

## Naming Conventions

Follow the **Azure Cloud Adoption Framework (CAF)** naming standard:

| Resource Type | Pattern | Example |
|---|---|---|
| Resource Group | `rg-<app>-<env>-<region>` | `rg-myapp-prod-aue` |
| Virtual Network | `vnet-<app>-<env>-<region>` | `vnet-myapp-prod-aue` |
| Subnet | `snet-<purpose>-<env>` | `snet-web-prod` |
| Network Security Group | `nsg-<purpose>-<env>` | `nsg-web-prod` |
| Storage Account | `st<app><env><###>` | `stmyappprod001` |
| Key Vault | `kv-<app>-<env>-<###>` | `kv-myapp-prod-001` |
| App Service Plan | `plan-<app>-<env>` | `plan-myapp-prod` |
| App Service | `app-<app>-<env>` | `app-myapp-prod` |
| SQL Server | `sql-<app>-<env>` | `sql-myapp-prod` |
| SQL Database | `sqldb-<app>-<env>` | `sqldb-myapp-prod` |
| Log Analytics | `log-<app>-<env>` | `log-myapp-prod` |
| Application Insights | `appi-<app>-<env>` | `appi-myapp-prod` |

Use `uniqueString(resourceGroup().id)` for globally unique names (e.g., storage accounts, Key Vaults).

---

## Bicep Coding Standards

### Parameters

- Always add `@description()` decorators to every parameter
- Use `@allowed()` for environment parameters: `['dev', 'staging', 'prod']`
- Use `@secure()` for all passwords and secrets — **never set default values on secure parameters**
- Use `@minLength()`, `@maxLength()`, `@minValue()`, `@maxValue()` where appropriate
- Prefer descriptive parameter names in camelCase

### Variables

- Use variables for computed values (e.g., resource names built from parameters)
- Keep naming logic in variables, not inline in resource definitions

### Resources

- Always use recent, stable API versions (within the last 2 years)
- Set `location` from a parameter, defaulting to `resourceGroup().location`
- Use the `parent` property instead of nested resource names
- Add `dependsOn` only when Bicep cannot infer the dependency automatically

### Modules

- Use modules for logical groupings (networking, compute, data, monitoring)
- Each module should have clearly defined parameters and outputs
- Prefer flat module structures over deeply nested ones

### Outputs

- Output only values needed by other modules or deployment scripts
- Never output secrets or sensitive values

---

## Security Requirements (Mandatory)

These rules are **non-negotiable** — all generated Bicep must comply:

1. **No hardcoded secrets** — use `@secure()` params, Key Vault references, or Entra ID authentication
2. **No public blob access** — always set `allowBlobPublicAccess: false` on storage accounts
3. **HTTPS only** — set `supportsHttpsTrafficOnly: true` on storage; enforce HTTPS on App Services
4. **TLS 1.2 minimum** — set `minimumTlsVersion: 'TLS1_2'` on all resources that support it
5. **Disable public network access** where possible — use private endpoints for databases, storage, Key Vault
6. **Network Security Groups** — attach an NSG to every subnet; deny inbound by default
7. **Managed identities** — prefer system-assigned managed identity over keys/passwords
8. **Azure Defender / Microsoft Defender** — enable where available
9. **Diagnostic settings** — send logs and metrics to Log Analytics workspace
10. **No hardcoded environment URLs** — use `environment()` function for Azure endpoints

---

## Bicep Linter

All code must pass the linter rules defined in `bicepconfig.json`. Key rules enforced:

- `secure-parameter-default`: **error** — no defaults on `@secure()` params
- `no-hardcoded-env-urls`: **error** — no hardcoded Azure URLs
- `outputs-should-not-contain-secrets`: **error** — no secrets in outputs
- `adminusername-should-not-be-literal`: **error** — parameterise admin usernames
- `no-unused-params` / `no-unused-vars`: **warning**
- `use-recent-api-versions`: **warning** (max age: 730 days)
- `no-hardcoded-location`: **warning** — use location parameter

---

## File Structure Conventions

```
demo-folder/
├── README.md           # Demo instructions and talking points
├── start/              # Starting files (comments/skeleton only)
│   └── main.bicep
└── completed/          # Finished reference files
    ├── main.bicep
    └── main.bicepparam
```

- `start/` files contain comments describing what to build — Copilot fills in the code
- `completed/` files are the reference solutions
- Use `main.bicep` as the entry point; modules go in a `modules/` subfolder

---

## Response Style

- Generate complete, deployable Bicep code — not pseudocode or partial snippets
- Include `@description()` on all parameters and outputs
- Add inline comments explaining non-obvious decisions (e.g., why a specific SKU is chosen)
- When generating modules, include both the module file and the parent template that consumes it
- Prefer Azure Verified Modules (AVM) patterns where applicable
