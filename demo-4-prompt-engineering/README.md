# Demo 4: Prompt Engineering — Best Practices for Bicep Quality

> **Duration:** ~5 minutes  
> **Goal:** Show that HOW you ask Copilot matters — better prompts produce better Bicep code

---

## What You'll Demonstrate

1. **Vague vs. specific prompts** — side-by-side comparison in Bicep
2. **Context techniques** — file names, parameter decorators, and existing resources guide suggestions
3. **Copilot Chat patterns** — `/explain`, `@workspace`, and `#file` references for Bicep
4. **Iterative refinement** — build up complex resources through conversation

---

## Live Demo Steps

### Step 1: Vague vs. Specific Prompts

Open `examples/prompt-comparison.bicep` and demonstrate both approaches:

**Bad prompt (vague):**
```bicep
// create a storage account
```

**Good prompt (specific):**
```bicep
// Create an Azure Storage Account with Standard_GRS redundancy, StorageV2 kind,
// TLS 1.2 minimum, HTTPS only, blob public access disabled,
// blob soft delete enabled for 14 days, and container soft delete for 7 days.
// Tag with environment and project. Use the naming convention: st{project}{env}{unique}.
```

Show how the specific prompt produces production-ready, secure code.

### Step 2: The Power of Context

Open `examples/context-matters.bicep` — show how:
1. **Good file names** → `networking.bicep` vs `resources.bicep`
2. **Existing parameters** → Having typed params guides Copilot
3. **Existing resources** → Copilot references them automatically
4. **Decorators** → `@allowed`, `@description`, `@minLength` improve suggestions

### Step 3: Copilot Chat Power Features for Bicep

| Command | What it does | Example |
|---------|-------------|---------|
| `/explain` | Explains Bicep resource | Select Key Vault → `/explain` |
| `/fix` | Fixes linter warnings | Select resource → `/fix` |
| `/doc` | Adds descriptions | Select module → `/doc` |
| `@workspace` | Searches project | `@workspace which module handles networking?` |
| `#file` | References file | `Add monitoring like #file:monitoring.bicep` |

### Step 4: Iterative Refinement

Show the "conversation" pattern:
1. Ask: *"Create an Azure Container Registry"*
2. Then: *"Add a geo-replication to East US"*
3. Then: *"Add a private endpoint in the pe-subnet from my VNet"*
4. Then: *"Add diagnostic settings to send logs to my Log Analytics workspace"*

---

## Talking Points

- "Copilot is only as good as the context you give it"
- "Parameter decorators are 'invisible prompts' — they guide Copilot's suggestions"
- "In Bicep, the file name and existing resources matter enormously"
- "Iterative refinement through Chat is like pair programming with an Azure expert"

---

## Key Takeaway

### The Bicep Prompt Pyramid

```
         ┌──────────────┐
         │   Iterate     │  ← Refine through conversation
        ┌┴──────────────┴┐
        │  Be Specific    │  ← SKU, settings, security, naming
       ┌┴────────────────┴┐
       │  Provide Context   │  ← Params, decorators, existing resources
      ┌┴──────────────────┴┐
      │  Structure Your Files │  ← Modules, clear file names
     └────────────────────────┘
```
