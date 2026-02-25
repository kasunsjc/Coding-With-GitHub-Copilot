# Demo 3: Build a Complete Azure Environment with Copilot

> **Duration:** ~5 minutes  
> **Goal:** Build a production-ready, multi-tier Azure environment from scratch using Copilot

---

## What You'll Demonstrate

1. **Scaffold from intent** — Copilot builds a full environment from high-level comments
2. **Resource dependencies** — Copilot understands implicit references between resources
3. **Security by default** — Private endpoints, managed identity, Key Vault references
4. **Parameter files** — Generate `.bicepparam` files from Bicep templates

---

## Architecture We're Building

```
┌─────────────────────────────────────────────────────┐
│                   Azure Resource Group               │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ App       │  │ Function │  │ Container         │  │
│  │ Service   │  │ App      │  │ Registry          │  │
│  └─────┬────┘  └─────┬────┘  └───────────────────┘  │
│        │              │                               │
│  ┌─────┴──────────────┴────────────────────────────┐ │
│  │              Virtual Network                     │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │ │
│  │  │ app      │ │ func     │ │ private-endpoint  │ │ │
│  │  │ subnet   │ │ subnet   │ │ subnet            │ │ │
│  │  └──────────┘ └──────────┘ └──────────────────┘ │ │
│  └─────────────────────────────────────────────────┘ │
│        │              │                               │
│  ┌─────┴──────┐ ┌────┴─────┐  ┌──────────────────┐  │
│  │ Key Vault  │ │ Storage  │  │ SQL Database      │  │
│  │ (secrets)  │ │ Account  │  │ (Entra auth)      │  │
│  └────────────┘ └──────────┘  └──────────────────┘  │
│                                                      │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Log Analytics  ←  App Insights  ←  Alerts       │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

---

## Live Demo Steps

### Step 1: Open the starter main.bicep

Open `start/main.bicep` — it has section comments describing each tier.

### Step 2: Generate resource by resource

1. Start with parameters — Copilot generates typed params with decorators
2. Move to networking — VNet with subnets for app, functions, private endpoints
3. Generate compute — App Service + Function App with managed identity
4. Generate data layer — SQL + Storage with private endpoints
5. Generate monitoring — Log Analytics + App Insights + alerts

### Step 3: Generate the parameter file

1. Open Copilot Chat
2. Ask: *"Generate a .bicepparam file for this Bicep template with sample dev environment values"*
3. Show the generated `main.bicepparam`

### Step 4: Validate

```bash
az bicep build --file main.bicep
az deployment group what-if --resource-group myRG --template-file main.bicep
```

---

## Talking Points

- "We built a production-grade Azure environment with ~10 resources in 5 minutes"
- "Copilot understood resource dependencies — App Service references the Plan ID"
- "It added managed identity by default — that's security awareness"
- "The what-if deployment lets us verify before deploying"

---

## Reference

See `completed/` folder for the full working infrastructure.
