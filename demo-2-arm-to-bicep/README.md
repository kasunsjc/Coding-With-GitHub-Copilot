# Demo 2: ARM Template to Bicep Conversion & Refactoring

> **Duration:** ~5 minutes  
> **Goal:** Show Copilot converting legacy ARM JSON templates to clean Bicep and refactoring into modules

---

## What You'll Demonstrate

1. **ARM to Bicep conversion** — Copilot converts verbose JSON to clean Bicep
2. **Refactoring into modules** — Extract resources into reusable Bicep modules
3. **Adding best practices** — Copilot improves security and compliance during conversion

---

## Live Demo Steps

### Part A: ARM JSON to Bicep (~3 min)

#### Step 1: Open the ARM template

Open `start/legacy-arm-template.json` — a classic ARM JSON template with a Storage Account, App Service, and Application Insights.

#### Step 2: Convert with Copilot Chat

1. Select the entire ARM JSON file
2. Open Copilot Chat (`Cmd+L` / `Ctrl+L`)
3. Type: *"Convert this ARM template to Bicep. Use best practices: add parameter decorators, use descriptive resource symbolic names, and add tags."*
4. Show the transformation to the audience
5. Highlight: verbose JSON → clean Bicep, expressions → native syntax

#### Step 3: Show what changed

| ARM JSON | Bicep |
|----------|-------|
| `[parameters('location')]` | `location` (direct param reference) |
| `[concat('storage', uniqueString(...))]` | String interpolation: `'storage${uniqueString(...)}'` |
| `"dependsOn": [...]` | Implicit dependencies via symbolic references |
| 80+ lines of JSON | ~40 lines of Bicep |

### Part B: Refactoring into Modules (~2 min)

#### Step 4: Open the converted Bicep

Open `start/monolith.bicep` — a single large Bicep file with everything in one place.

#### Step 5: Refactor with Copilot Chat

1. Select the entire file
2. Ask Copilot Chat: *"Refactor this into a modular Bicep structure. Create a main.bicep that calls separate modules for networking, compute, and monitoring."*
3. Show the before (one big file) → after (main + modules)

---

## Talking Points

- "This is a real scenario — every Azure team has legacy ARM templates"
- "Copilot converted 80 lines of JSON into 40 lines of clean Bicep"
- "It removed explicit dependsOn — Bicep handles dependencies automatically"
- "The module refactoring is where Copilot saves hours of manual extraction"

---

## Reference

See `completed/` folder for the converted Bicep files and module structure.
