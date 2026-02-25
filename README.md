# Coding with AI: How GitHub Copilot Transforms Developer Productivity

> **Session Duration:** 40 minutes (Hands-on Demo)  
> **Presenter:** Kasun Rajapakse  
> **Date:** February 2026  
> **Technology:** Azure Bicep (Infrastructure as Code)

---

## Session Overview

This hands-on session demonstrates how GitHub Copilot fundamentally changes the way developers write Infrastructure as Code with Azure Bicep. Through live coding demos, we explore real-world use cases, establish best practices for productivity and quality, and show how teams can adopt AI-assisted IaC development without compromising engineering standards.

---

## Why Bicep?

- **Azure's native IaC language** — first-class Azure Resource Manager support
- **Declarative syntax** — cleaner than ARM JSON templates
- **Copilot excels at Bicep** — well-structured, pattern-heavy language
- **Relatable for any Azure team** — infrastructure touches every project

---

## Agenda (40 Minutes)

| Time | Section | Demo |
|------|---------|------|
| 0–3 min | **Opening & Context** | Quick intro — what is Copilot and why it matters for IaC |
| 3–12 min | **Real-World Use Cases** | Demo 1: Generate Azure resources from comments → Demo 2: Convert ARM JSON to Bicep |
| 12–22 min | **Best Practices for Productivity & Quality** | Demo 3: Build a full Azure environment → Demo 4: Prompt engineering for Bicep |
| 22–32 min | **AI Without Compromising Standards** | Demo 5: Linting, security, team policies, and governance |
| 32–38 min | **Live Q&A / Freestyle Copilot** | Audience-driven infrastructure coding |
| 38–40 min | **Key Takeaways & Close** | Summary slide |

---

## Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/) (latest)
- [GitHub Copilot Extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
- [GitHub Copilot Chat Extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- [Bicep Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (2.60+)
- GitHub Copilot license (Individual, Business, or Enterprise)

---

## Project Structure

```
Coding-With-GitHub-Copilot/
├── README.md                              # This file — session guide
├── PRESENTER-NOTES.md                     # Detailed talking points & timings
├── CHEAT-SHEET.md                         # Quick Bicep + Copilot reference
│
├── demo-1-resource-generation/            # Real-world use case: Bicep from comments
│   ├── README.md
│   ├── start/                             # Starting files (comments only)
│   └── completed/                         # Finished Bicep files (reference)
│
├── demo-2-arm-to-bicep/                   # Real-world use case: ARM → Bicep conversion
│   ├── README.md
│   ├── start/                             # ARM JSON templates to convert
│   └── completed/                         # Converted Bicep files
│
├── demo-3-full-environment/               # Best practices: build complete Azure infra
│   ├── README.md
│   ├── start/                             # Skeleton with comments
│   └── completed/                         # Full multi-resource deployment
│
├── demo-4-prompt-engineering/             # Best practices: writing effective prompts
│   ├── README.md
│   └── examples/                          # Good vs bad prompt examples
│
├── demo-5-team-adoption/                  # AI + engineering standards for IaC
│   ├── README.md
│   ├── .github/
│   └── examples/
│
└── slides/
    └── key-takeaways.md
```

---

## Key Messages

### 1. Real-World Use Cases
- **Resource generation from comments** — describe the Azure resource, Copilot writes the Bicep
- **ARM to Bicep conversion** — modernize legacy JSON templates with Copilot
- **Module creation** — Copilot generates reusable Bicep modules
- **Parameter files** — auto-generate `.bicepparam` files from templates

### 2. Best Practices for Productivity & Quality
- **Context is king** — good file names, parameters, and descriptions = better suggestions
- **Prompt engineering** — write clear resource descriptions to guide Copilot
- **Review everything** — treat Copilot as a junior infrastructure engineer
- **Use modules** — Copilot follows your modular patterns

### 3. AI Without Compromising Standards
- **Bicep linter** — `bicepconfig.json` enforces rules on all code
- **What-If deployments** — validate before deploying regardless of author
- **Security scanning** — no hardcoded secrets, proper RBAC, private endpoints
- **Team conventions** — `.github/copilot-instructions.md` enforces project-level rules

---

## Quick Start

```bash
# Verify prerequisites
az --version
az bicep version

# Validate a Bicep file
az bicep build --file demo-3-full-environment/completed/main.bicep

# Preview deployment (What-If)
az deployment group what-if \
  --resource-group myResourceGroup \
  --template-file demo-3-full-environment/completed/main.bicep \
  --parameters demo-3-full-environment/completed/main.bicepparam
```

---

## Resources

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Bicep Playground](https://aka.ms/bicepdemo)
- [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/using-github-copilot/best-practices-for-using-github-copilot)
- [Bicep Linter Rules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter)

---

> **Tip for attendees:** Follow along with each demo folder. The `start/` folder has the beginning state (comments only), and `completed/` has the finished reference Bicep code.
