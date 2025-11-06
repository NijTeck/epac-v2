# NIST 800-53 Enterprise Policy as Code (EPAC)

This repository contains the Enterprise Policy as Code (EPAC) deployment configuration for **NIST 800-53 Rev. 5** compliance framework only.

## Overview

This implementation focuses exclusively on NIST 800-53 Rev. 5 (built-in Azure policy set ID: `179d1daa-458f-4e47-8086-2a68d0d6c38f`), providing:

- ✅ **Automated deployment** via GitHub Actions
- ✅ **Automated remediation** for non-compliant resources
- ✅ **Dual environments**: epac-dev (testing) and tenant (production)
- ✅ **238 NIST 800-53 policies** deployed to Tenant Root Group
- ✅ **Currently in Audit mode** (92.4% reporting, 1.7% enforcing)
- ✅ **No custom policies needed** - uses built-in Azure policy set

## Quick Links

- 📖 **[Quick Start Guide](QUICKSTART.md)** - Get deployed in minutes
- 🔒 **[NIST Compliance Guide](NIST-COMPLIANCE.md)** - Understanding audit vs enforcement mode
- 🚀 **Deployment Status**: Working on branch `working-nist800-controls`

## Repository Structure

```
├── Definitions/                              # EPAC configuration (only folder EPAC reads)
│   ├── global-settings.jsonc                # Environment configuration
│   ├── policyAssignments/
│   │   ├── nist-800-53-assignments.jsonc    # NIST 800-53 assignment config
│   │   └── nist-800-53-parameters.csv       # Policy parameters (NIST only)
│   ├── policyDocumentations/                # Optional: compliance reports
│   └── policyExemptions/                    # Optional: exemption management
│
├── .github/workflows/                        # GitHub Actions automation
│   ├── epac-dev-workflow.yml               # Dev environment deployment
│   ├── epac-tenant-workflow.yml            # Production deployment
│   ├── plan.yml                            # Reusable plan template
│   ├── deploy-policy.yml                   # Reusable policy deploy template
│   └── deploy-roles.yml                    # Reusable roles deploy template
│
└── Output/                                   # Auto-generated plans (gitignored)
```

## Prerequisites

### Azure Requirements

1. **Azure Tenant** with management groups configured
2. **Service Principal** with permissions:
   - Reader (at deployment root scope)
   - Resource Policy Contributor (at deployment root scope)
   - Role Based Access Control Administrator (at deployment root scope)
3. **Management Groups** for:
   - Dev environment (epac-dev)
   - Production Prod and Nonprod scopes

### Local Development Requirements

- PowerShell 7.0 or later
- Azure PowerShell module: `Install-Module Az -Force`
- EPAC PowerShell module: `Install-Module EnterprisePolicyAsCode -Force`

### GitHub Requirements

- GitHub repository with Actions enabled
- GitHub Environments configured (see setup below)
- Federated credentials configured for OIDC authentication

## Quick Start

### 1. Configure Your Environment

Edit `Definitions/global-settings.jsonc`:

```jsonc
{
  "pacOwnerId": "8175d5de-d921-4a3c-b79f-5566e047f872",  // Keep this unique ID
  "pacEnvironments": [
    {
      "pacSelector": "epac-dev",
      "tenantId": "<YOUR-TENANT-ID>",                    // Replace
      "deploymentRootScope": "/providers/Microsoft.Management/managementGroups/<YOUR-DEV-MG>",  // Replace
      "managedIdentityLocation": "eastus"                // Replace with your region
    },
    {
      "pacSelector": "tenant",
      "tenantId": "<YOUR-TENANT-ID>",                    // Replace
      "deploymentRootScope": "/providers/Microsoft.Management/managementGroups/<YOUR-PROD-MG>",  // Replace
      "managedIdentityLocation": "eastus"                // Replace with your region
    }
  ]
}
```

### 2. Configure Policy Assignments

Edit `Definitions/policyAssignments/nist-800-53-assignments.jsonc`:

Replace the placeholder management group IDs with your actual management groups:

```jsonc
{
  "children": [
    {
      "nodeName": "Prod/",
      "scope": {
        "epac-dev": ["/providers/Microsoft.Management/managementGroups/<YOUR-DEV-PROD-MG>"],
        "tenant": ["/providers/Microsoft.Management/managementGroups/<YOUR-PROD-MG>"]
      }
    },
    {
      "nodeName": "Nonprod/",
      "scope": {
        "epac-dev": ["/providers/Microsoft.Management/managementGroups/<YOUR-DEV-NONPROD-MG>"],
        "tenant": ["/providers/Microsoft.Management/managementGroups/<YOUR-NONPROD-MG>"]
      }
    }
  ]
}
```

### 3. Review Policy Parameters

The `Definitions/policyAssignments/nist-800-53-parameters.csv` file contains configuration for all NIST 800-53 policies.

- **prodEffect**: Effect for production (Audit, Deny, Disabled, etc.)
- **nonprodEffect**: Effect for non-production
- **Initial setting**: All policies set to "Audit" for safe deployment

You can modify effects after initial deployment based on compliance requirements.

## Deployment Methods

### Method 1: GitHub Actions (Recommended)

#### Setup GitHub Environments

Create four GitHub environments with secrets:

| Environment | Secrets Required | Protection Rules |
|-------------|------------------|------------------|
| EPAC-DEV | AZURE_CLIENT_ID, AZURE_TENANT_ID | None |
| TENANT-PLAN | AZURE_CLIENT_ID, AZURE_TENANT_ID | None |
| TENANT-DEPLOY-POLICY | AZURE_CLIENT_ID, AZURE_TENANT_ID | Required reviewers, branch: main |
| TENANT-DEPLOY-ROLES | AZURE_CLIENT_ID, AZURE_TENANT_ID | Required reviewers, branch: main |

See [SERVICE_PRINCIPALS.md](SERVICE_PRINCIPALS.md) for service principal setup.

#### Deployment Workflow

1. **Create feature branch**: `git checkout -b feature/nist-config`
2. **Make changes** to Definitions/ files
3. **Push to GitHub**: `git push origin feature/nist-config`
4. **Automatic deployment to epac-dev** (no approval needed)
5. **Create PR to main** for production deployment
6. **Merge PR** - triggers production deployment with approval gates

### Method 2: Local Deployment

#### Authenticate to Azure

```powershell
# Option 1: User authentication
Connect-AzAccount -Tenant <YOUR-TENANT-ID>

# Option 2: Service Principal with secret
$credential = Get-Credential
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant <YOUR-TENANT-ID>

# Option 3: Service Principal with certificate
Connect-AzAccount -ServicePrincipal -CertificateThumbprint <THUMBPRINT> -ApplicationId <APP-ID> -Tenant <YOUR-TENANT-ID>
```

#### Generate Deployment Plan

```powershell
# Install EPAC module (first time only)
Install-Module EnterprisePolicyAsCode -Force

# Generate plan for dev environment
Build-DeploymentPlans -PacEnvironmentSelector "epac-dev" -InformationAction Continue

# Review generated plans in Output/ folder
Get-ChildItem ./Output
```

#### Deploy Policies

```powershell
# Deploy policy assignments
Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue

# Deploy role assignments for managed identities
Deploy-RolesPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue
```

#### Deploy to Production

```powershell
# Generate production plan
Build-DeploymentPlans -PacEnvironmentSelector "tenant" -InformationAction Continue

# Review plan carefully before deploying

# Deploy to production
Deploy-PolicyPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
Deploy-RolesPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
```

## Policy Parameter Management

The CSV file allows easy configuration of 300+ NIST 800-53 policies:

### CSV Structure

```csv
name,displayName,groupNames,policySets,prodEffect,nonprodEffect
<policy-guid>,<policy-name>,NIST_SP_800-53_R5_<control>,NIST-800-53: Audit,Audit,Audit
```

### Common Effect Values

- **Audit**: Log non-compliance (recommended for initial deployment)
- **Deny**: Block non-compliant resources
- **AuditIfNotExists**: Audit if resource doesn't exist
- **DeployIfNotExists**: Auto-remediate by deploying resources
- **Disabled**: Don't evaluate policy

### Modifying Policy Effects

1. Open `Definitions/policyAssignments/nist-800-53-parameters.csv`
2. Find the policy by name or GUID
3. Change `prodEffect` or `nonprodEffect` column
4. Commit and deploy

**Example**: Change from Audit to Deny for production:
```csv
name,prodEffect,nonprodEffect
"a4af4a39-4135-47fb-b175-47fbdf85311d","Deny","Audit"
```

## Monitoring and Compliance

### View Compliance in Azure Portal

1. Navigate to **Azure Policy** in Azure Portal
2. Select **Compliance**
3. Filter by **NIST SP 800-53 Rev. 5**
4. Review compliance status by management group

### View Policy Assignments

```powershell
# List NIST 800-53 assignments
Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" }
```

## Troubleshooting

### Common Issues

**Issue**: Plan generation fails with "Management group not found"
- **Solution**: Verify management group IDs in `global-settings.jsonc` and `nist-800-53-assignments.jsonc`

**Issue**: GitHub Actions fails with authentication error
- **Solution**: Verify federated credentials are configured correctly (see SERVICE_PRINCIPALS.md)

**Issue**: Local deployment fails with permission error
- **Solution**: Verify service principal has required permissions at management group scope

**Issue**: Policies not enforcing
- **Solution**: Check policy effect is not "Audit" or "Disabled". Verify role assignments for managed identities.

### Get Help

- Review [QUICKSTART.md](QUICKSTART.md) for quick deployment guide
- Review [NIST-COMPLIANCE.md](NIST-COMPLIANCE.md) for compliance and enforcement
- Check EPAC documentation: https://aka.ms/epac
- Open GitHub issue for bugs or questions

## What's Different from Multi-Framework EPAC?

This implementation is **simplified** because:

1. ❌ **No policyDefinitions/ folder** - NIST 800-53 is built-in
2. ❌ **No policySetDefinitions/ folder** - NIST 800-53 is built-in
3. ✅ **Only policyAssignments/** - Just assign and configure
4. ✅ **Filtered CSV** - Only ~300 NIST policies (not 1000+ mixed frameworks)
5. ✅ **Single framework focus** - No ASB, PCI-DSS, or other frameworks

## Next Steps

1. ✅ Configure `global-settings.jsonc` with your tenant/management groups
2. ✅ Configure `nist-800-53-assignments.jsonc` with your scopes
3. ✅ Set up service principals and GitHub environments
4. ✅ Deploy to epac-dev for testing
5. ✅ Review compliance results
6. ✅ Adjust policy effects in CSV as needed
7. ✅ Deploy to production

## License

This project uses the Microsoft EPAC framework. See [LICENSE](LICENSE) for details.
