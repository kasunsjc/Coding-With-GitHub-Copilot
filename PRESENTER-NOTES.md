# Presenter Notes — Coding with AI: GitHub Copilot for Bicep

## Pre-Session Setup (10 min before)

### Environment Checklist
- [ ] VS Code open with workspace loaded
- [ ] Bicep extension installed and working (green status bar icon)
- [ ] GitHub Copilot extension active (Copilot icon in status bar)
- [ ] Azure CLI logged in (`az account show`)
- [ ] Terminal ready for `az bicep build` commands
- [ ] All `start/` files open in tabs, `completed/` files closed
- [ ] Font size: 16–18pt (Cmd+= to zoom)
- [ ] Zen mode ready (Cmd+K Z) — hides sidebar for focus
- [ ] Disable notifications (Do Not Disturb)

### Quick Test
```bash
# Verify tools work
az bicep version
az account show --query name -o tsv
```

---

## Opening (2 min)

### Key Message
> "Today I'll show you how GitHub Copilot transforms infrastructure-as-code development.
> We're using Azure Bicep — Azure's native IaC language — to demonstrate three things:
> real-world use cases, best practices for quality, and how teams adopt AI safely."

### Audience Hook
> "How many of you have written an ARM template? (pause)
> How many enjoyed it? (laugh)
> What if I told you Copilot can turn comments into production-ready Bicep in seconds?"

---

## Demo 1: Resource Generation from Comments (5 min)

### Setup
Open `demo-1-resource-generation/start/main.bicep`

### Flow
1. **Show the comments** — "These are plain English descriptions of 5 resources"
2. **Place cursor after first comment** (Storage Account)
3. **Wait for ghost text** — Copilot should suggest the full resource
4. **Accept with Tab** — highlight the naming, SKU, security settings
5. **Repeat for VNet** — show how subnets are included
6. **Skip to Key Vault** — show RBAC authorization, purge protection

### Timing Tips
- Don't do all 5 resources live — do 2-3 and say "you get the idea"
- If Copilot is slow, have `completed/main.bicep` ready as backup
- Spend 30 seconds on the best suggestion explaining WHY it's good

### Talking Points
- "Notice the naming convention — Copilot reads the parameters we set up"
- "It added TLS 1.2 and HTTPS-only — because good prompts produce secure code"
- "This would have taken 15 minutes to type manually"

### Backup Plan
If Copilot doesn't generate good output, open `completed/main.bicep` and say:
> "In the interest of time, here's what Copilot generated for me earlier."

---

## Demo 2: ARM to Bicep Conversion & Refactoring (8 min)

### Part A: ARM → Bicep (3 min)

#### Setup
Open `demo-2-arm-to-bicep/start/legacy-arm-template.json`

#### Flow
1. **Show ARM template** — "This is 100+ lines of JSON. Hard to read, hard to maintain."
2. **Open Copilot Chat** (Cmd+Shift+I or click Copilot icon)
3. **Prompt:** `Convert this ARM template to Bicep. Use modern best practices: modules, decorators, strong typing.`
4. **Review output** — highlight differences: no `dependsOn`, cleaner syntax, type safety
5. **Compare with** `completed/converted.bicep`

#### Key Points
- ARM JSON → Bicep is 40-60% fewer lines
- No more `[resourceId()]` or `[concat()]` — Bicep uses natural references
- Copilot handles the translation AND adds improvements

### Part B: Monolith → Modular (5 min)

#### Setup
Open `demo-2-arm-to-bicep/start/monolith.bicep`

#### Flow
1. **Scroll through** — "This is a 200+ line single file. Works, but hard to maintain."
2. **Copilot Chat prompt:** `Refactor this monolith.bicep into a modular structure with separate modules for networking, compute, data, and monitoring.`
3. **Review the module structure** Copilot suggests
4. **Open completed files** — walk through `modular/main.bicep` and 1-2 modules

#### Key Points
- "Copilot understands that networking should include VNet + NSG"
- "The main.bicep becomes an orchestrator — clean, readable, 50 lines"
- "Each module is independently testable and reusable"

---

## Demo 3: Full Environment Build (10 min)

### Setup
Open `demo-3-full-environment/start/main.bicep`

### Flow
1. **Show the architecture diagram** in README.md (30 sec)
2. **Walk through the parameters** — show decorators guiding Copilot
3. **Start generating resources** — let Copilot fill in 2-3 resources
4. **Jump to completed file** when time gets tight
5. **Highlight key patterns:**
   - Managed identity on App Service
   - RBAC role assignments (not connection strings)
   - Key Vault references
   - Diagnostic settings flowing to Log Analytics
   - Environment-conditional logic (prod vs dev)
6. **Show parameter file** (`main.bicepparam`) — "Environment configs stay separate"

### Timing Tips
- This is the LONGEST demo — watch the clock
- Do 3-4 resources live, then switch to completed file
- Spend most time on the PATTERNS, not typing

### Must-Hit Points
- Managed Identity + RBAC = no secrets to manage
- `what-if` deployment preview = safe deployments
- Parameter files = environment separation

---

## Demo 4: Prompt Engineering (5 min)

### Setup
Open `demo-4-prompt-engineering/examples/prompt-comparison.bicep`

### Flow
1. **Show vague prompt** → show the minimal output
2. **Show specific prompt** → show the production-ready output
3. **Side by side** — "Same resource, 10x better quality"
4. **Switch to** `context-matters.bicep`
5. **Show Technique 2** — existing resources create context chains
6. **Show Technique 6** — conditional patterns teach environment awareness

### Key Message
> "The #1 productivity tip: invest 30 seconds in a better prompt,
> save 10 minutes of fixing the output."

---

## Demo 5: Team Adoption (8 min)

### Setup
Open `demo-5-team-adoption/.github/copilot-instructions.md`

### Flow
1. **Custom instructions** (2 min) — walk through key sections
   - "This file lives in your repo — every team member gets the same Copilot behavior"
   - Highlight: naming conventions, security requirements, tagging policy
2. **PR template** (1 min) — open `pull_request_template.md`
   - "Even AI-generated code gets reviewed, with IaC-specific checkpoints"
3. **Security anti-patterns** (3 min) — open `security-awareness.bicep`
   - Show 2-3 pairs: insecure → secure
   - "Without instructions, Copilot might suggest the left side.
     WITH instructions, it suggests the right side."
4. **Linter config** (1 min) — open `bicepconfig.json`
   - "Your automated safety net — catches issues on every save"
5. **Adoption policy** (1 min) — briefly show `team-adoption-policy.md`
   - "Start small, measure results, expand with confidence"

### Must-Hit Point
> "Defense in depth: instructions → linter → build → review → Azure Policy.
> Five layers, and Copilot works within all of them."

---

## Closing (2 min)

### Summary Slide Points
1. **Real-world use cases:** Resource generation, ARM conversion, full environments
2. **Quality practices:** Specific prompts, context techniques, iterative refinement
3. **Team adoption:** Custom instructions, linting, PR templates, phased rollout

### Call to Action
> "Three things you can do THIS WEEK:
> 1. Install Copilot and the Bicep extension — try Demo 1 with your own resources
> 2. Create a `copilot-instructions.md` for your team's IaC repo
> 3. Add `bicepconfig.json` with the linter rules we showed today"

### Final Quote
> "AI doesn't replace engineers — it amplifies them.
> The teams that learn to work WITH AI will build faster, safer, and better."

---

## Q&A Preparation

### Likely Questions & Answers

**Q: Does Copilot work offline?**
A: No, it requires internet connectivity. It sends context to GitHub's servers for suggestion generation. No code is stored.

**Q: Is our code sent to OpenAI/GitHub?**
A: With Copilot Business/Enterprise, your code is NOT used for training. Telemetry can be configured by your org admin.

**Q: What about compliance (SOC 2, ISO)?**
A: Copilot Business is SOC 2 Type II certified. Enterprise adds additional controls. The generated code must still pass your compliance checks.

**Q: How does it compare to Amazon CodeWhisperer / Tabnine?**
A: Copilot has the deepest VS Code + Azure integration, especially for Bicep. CodeWhisperer focuses on AWS. Tabnine offers on-premises models.

**Q: What if Copilot suggests wrong resource API versions?**
A: The Bicep linter (`use-recent-api-versions`) catches outdated APIs. Always validate with `az bicep build`.

**Q: How much does it cost?**
A: $19/user/month (Business) or $39/user/month (Enterprise). ROI typically seen in first week from time savings.

**Q: Can I use it for Terraform instead of Bicep?**
A: Yes! Copilot works great with Terraform HCL. The same principles apply — good prompts, context files, linting.
