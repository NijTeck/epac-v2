# NIST 800-53 Repository Structure

## What You Actually Need

For NIST 800-53 deployment, you need a **minimal structure** because NIST 800-53 is a **built-in Azure policy set**.

### Required Files

```
your-repo/
├── Definitions/
│   ├── global-settings.jsonc                      ✅ REQUIRED
│   └── policyAssignments/
│       ├── nist-800-53-assignments.jsonc          ✅ REQUIRED
│       └── nist-800-53-parameters.csv             ✅ REQUIRED
│
└── .github/workflows/
    ├── epac-dev-workflow.yml                      ✅ REQUIRED (for automation)
    ├── epac-tenant-workflow.yml                   ✅ REQUIRED (for automation)
    ├── plan.yml                                   ✅ REQUIRED (reusable template)
    ├── deploy-policy.yml                          ✅ REQUIRED (reusable template)
    └── deploy-roles.yml                           ✅ REQUIRED (reusable template)
```

### Optional Folders

```
your-repo/
├── Definitions/
│   ├── policyDocumentations/                      📄 OPTIONAL (for compliance reports)
│   └── policyExemptions/                          📄 OPTIONAL (for exemptions)
```

### NOT Needed

```
❌ policyDefinitions/          - NOT NEEDED (NIST 800-53 is built-in)
❌ policySetDefinitions/        - NOT NEEDED (NIST 800-53 is built-in)
```

## Why So Simple?

**NIST 800-53 Rev. 5 is a built-in Azure policy set** with ID: `179d1daa-458f-4e47-8086-2a68d0d6c38f`

This means:
- Microsoft already defined all 300+ policies
- Microsoft already grouped them into a policy set (initiative)
- You just need to **assign** it to your management groups
- You just need to **configure parameters** (effects, settings)

## What About StarterKit?

The `StarterKit/` folder contains **examples** for different scenarios:
- `Definitions-Common` - Example with custom policies
- `Definitions-GitHub-Flow` - Example for GitHub workflow
- `Definitions-Microsoft-Release-Flow` - Example for release workflow

**You don't use these directly.** They're references. EPAC only reads from your `Definitions/` folder at the repo root.

## File Purposes

### global-settings.jsonc
Defines your environments (epac-dev, tenant) and where to deploy policies.

### nist-800-53-assignments.jsonc
Defines:
- Which policy set to assign (NIST 800-53)
- Where to assign it (Prod, Nonprod management groups)
- Which parameter file to use

### nist-800-53-parameters.csv
Configures each of the 300+ NIST 800-53 policies:
- Effect (Audit, Deny, Disabled, etc.)
- Parameters (thresholds, settings)
- Different values for Prod vs Nonprod

## Comparison: Multi-Framework vs NIST-Only

### Multi-Framework Setup (Complex)
```
Definitions/
├── policyDefinitions/          # Custom policies
├── policySetDefinitions/       # Custom policy sets
├── policyAssignments/
│   ├── asb-assignments.jsonc   # Azure Security Benchmark
│   ├── pci-assignments.jsonc   # PCI-DSS
│   ├── nist-assignments.jsonc  # NIST 800-53
│   └── parameters.csv          # 1000+ policies mixed together
```

### NIST 800-53 Only (Simple)
```
Definitions/
├── policyAssignments/
│   ├── nist-800-53-assignments.jsonc   # Only NIST
│   └── nist-800-53-parameters.csv      # Only NIST policies (~300)
└── global-settings.jsonc
```

## How EPAC Works

1. **You create**: Assignment files and parameter CSV
2. **EPAC reads**: Your Definitions/ folder
3. **EPAC generates**: Deployment plan (policy-plan.json, roles-plan.json)
4. **EPAC deploys**: To Azure (creates assignments, role assignments)

## Local vs GitHub Actions

### Local Deployment
```powershell
# Authenticate
Connect-AzAccount

# Generate plan
Build-DeploymentPlans -PacEnvironmentSelector "epac-dev"

# Review plan in Output/ folder

# Deploy
Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev"
Deploy-RolesPlan -PacEnvironmentSelector "epac-dev"
```

### GitHub Actions
1. Push changes to Definitions/
2. GitHub Actions automatically runs Build-DeploymentPlans
3. Review plan in PR
4. Merge PR
5. GitHub Actions automatically deploys

Both use the **same Definitions/ folder** and **same EPAC logic**.

## Summary

✅ **Keep it simple**: Only 3 files needed in Definitions/
✅ **NIST 800-53 is built-in**: No custom policy definitions
✅ **Optional folders**: Add policyDocumentations/ and policyExemptions/ only if needed
✅ **StarterKit is reference**: Don't copy it, just reference it
✅ **One source of truth**: Definitions/ folder is all EPAC reads
