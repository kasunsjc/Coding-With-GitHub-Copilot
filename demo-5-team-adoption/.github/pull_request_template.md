## Description
<!-- Brief description of infrastructure changes -->

## Type of Change
- [ ] New resource / module
- [ ] Resource modification
- [ ] Resource deletion
- [ ] Configuration change (parameters, variables)
- [ ] Module refactoring
- [ ] Documentation only

## Infrastructure Changes
<!-- List the Azure resources being added, modified, or removed -->
| Resource | Action | Environment(s) |
|----------|--------|-----------------|
|          |        |                 |

## Pre-Deployment Checklist

### Security
- [ ] No hardcoded secrets, passwords, or connection strings
- [ ] Sensitive parameters use `@secure()` decorator
- [ ] Managed identity used where possible (no connection strings)
- [ ] TLS 1.2 minimum enforced on all applicable resources
- [ ] Public network access disabled for production resources
- [ ] Private endpoints configured for data-plane access (prod)
- [ ] Key Vault uses RBAC authorization (not access policies)
- [ ] Blob public access disabled on storage accounts
- [ ] NSG rules follow least-privilege principle

### Quality
- [ ] All parameters have `@description()` decorators
- [ ] Resources follow naming convention: `{abbr}-{project}-{env}-{unique}`
- [ ] All resources include required tags (environment, project, managedBy)
- [ ] `az bicep build` passes without errors
- [ ] Linter rules in `bicepconfig.json` pass (no warnings)
- [ ] Environment-specific conditional logic is correct (dev vs prod)

### Operational Readiness
- [ ] `what-if` deployment reviewed for unintended changes
- [ ] Monitoring/alerting configured for new resources
- [ ] Diagnostic settings send logs to Log Analytics
- [ ] RBAC role assignments follow least-privilege
- [ ] Rollback plan documented (if applicable)

### Copilot Usage Transparency
- [ ] AI-generated code has been reviewed and understood
- [ ] Copilot suggestions verified against Azure documentation
- [ ] No AI-generated placeholder values left in code (e.g., `TODO`, `CHANGEME`)

## What-If Output
<!-- Paste relevant `az deployment group what-if` output -->
```
<paste what-if output here>
```

## Additional Notes
<!-- Any context for reviewers: design decisions, trade-offs, risks -->
