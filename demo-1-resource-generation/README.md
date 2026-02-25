# Demo 1: Azure Resource Generation from Comments

> **Duration:** ~5 minutes  
> **Goal:** Show how Copilot turns Bicep comments into complete Azure resource definitions

---

## What You'll Demonstrate

1. **Comment-driven IaC** — Write a comment describing an Azure resource, Copilot generates it
2. **Parameter inference** — Copilot auto-generates parameters with decorators
3. **Multiple resources** — Copilot understands resource dependencies and references

---

## Live Demo Steps

### Step 1: Open the starter file

Open `start/main.bicep` — it contains only comments describing Azure resources.

### Step 2: Let Copilot generate resources

1. Place your cursor after each comment block
2. Press `Enter` and wait for Copilot's suggestion (ghost text)
3. Press `Tab` to accept, or `Ctrl+→` to accept word-by-word
4. Show the audience the suggestion before accepting

### Step 3: Walk through each resource

| Resource | What to highlight |
|----------|-------------------|
| **Storage Account** | Copilot knows valid SKU names, kind, and TLS settings |
| **Virtual Network** | Generates address space and subnets with CIDR blocks |
| **App Service Plan** | Copilot picks Linux/Windows, correct SKU tier |
| **Key Vault** | Includes access policies, soft delete, and purge protection |
| **SQL Server + Database** | Shows resource dependencies and parent-child relationships |

### Step 4: Show Copilot Chat (bonus)

- Select the generated Storage Account resource
- Open Copilot Chat (`Cmd+I` / `Ctrl+I`)
- Ask: *"Add diagnostic settings to send metrics to a Log Analytics workspace"*
- Show how Chat enhances existing Bicep code

---

## Talking Points

- "I wrote zero Bicep resource blocks — only described what I wanted in comments"
- "Copilot knew the valid SKU names, API versions, and required properties"
- "It even added security best practices like TLS 1.2 and soft delete"
- "But notice — I still reviewed every property before accepting"

---

## Reference

Compare your live results against `completed/main.bicep` for reference.
