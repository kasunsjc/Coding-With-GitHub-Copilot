# Team Adoption Policy: GitHub Copilot for Infrastructure as Code

## Purpose
This policy defines how our team uses GitHub Copilot for Azure Bicep development to maximize productivity while maintaining security, quality, and compliance standards.

---

## Guiding Principles

1. **Copilot is an accelerator, not a replacement** — Engineers own and understand every line of code
2. **Trust but verify** — All AI-generated code goes through the same review process as human-written code
3. **Guardrails over gatekeeping** — We enable Copilot with safeguards, not restrictions
4. **Continuous improvement** — We measure results and refine our approach

---

## Rollout Plan

### Phase 1: Pilot (Weeks 1–2)
- **Scope:** 2–3 engineers, non-production modules only
- **Focus:** Learn Copilot for Bicep, establish initial `copilot-instructions.md`
- **Measure:** Time to create new modules, developer satisfaction
- **Gate:** No security issues introduced, team comfortable with workflow

### Phase 2: Expand (Weeks 3–4)
- **Scope:** Full IaC team, all environments
- **Focus:** Production templates, module library, CI/CD integration
- **Measure:** PR cycle time, deployment success rate, linter violations
- **Gate:** Metrics at or above pre-Copilot baseline

### Phase 3: Optimize (Ongoing)
- **Scope:** Cross-team sharing, advanced patterns
- **Focus:** Refine instructions, share learnings, build reusable module library
- **Measure:** Module reuse rate, new engineer onboarding time

---

## Usage Guidelines

### DO
- Use Copilot for scaffolding new resources and modules
- Use Copilot Chat to explain unfamiliar ARM/Bicep syntax
- Use Copilot for converting ARM JSON to Bicep
- Use Copilot to generate parameter descriptions and decorators
- Review every suggestion before accepting
- Share effective prompts with the team

### DON'T
- Accept suggestions blindly without understanding them
- Use Copilot-generated secrets, passwords, or sample credentials
- Skip code review because "Copilot wrote it"
- Disable linter rules to make Copilot output compile
- Use Copilot on repositories containing classified/restricted data (unless approved)

---

## Quality Gates

| Gate | Tool | When |
|------|------|------|
| Linter | `bicepconfig.json` | On save (VS Code) |
| Build validation | `az bicep build` | Pre-commit hook |
| What-if analysis | `az deployment group what-if` | PR pipeline |
| Security scan | Defender for DevOps / Checkov | PR pipeline |
| Human review | PR template checklist | Before merge |
| Policy compliance | Azure Policy | On deployment |

---

## Metrics to Track

| Metric | How to Measure | Target |
|--------|----------------|--------|
| Module creation time | Avg hours per new module (before vs after) | 40% reduction |
| PR cycle time | Time from PR open to merge | 25% reduction |
| Linter violations per PR | CI/CD pipeline stats | Decrease over time |
| Security findings | Defender for DevOps reports | Zero critical/high |
| Deployment success rate | Pipeline success % | ≥ 95% |
| Developer satisfaction | Monthly survey (1–5) | ≥ 4.0 |

---

## Review Cadence
- **Weekly** (Phase 1–2): 15-min standup on Copilot experiences
- **Monthly** (Phase 3+): Metrics review, instructions update, prompt sharing
- **Quarterly**: Policy review and update

---

## Ownership
- **Policy owner:** [Platform Engineering Lead]
- **Last updated:** [Date]
- **Next review:** [Date + 3 months]
