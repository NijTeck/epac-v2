# Quick Start Guide

Get NIST 800-53 policies deployed in minutes.

## Prerequisites

- Azure subscription with Owner access
- GitHub account
- Azure CLI installed locally

## Option 1: Deploy via GitHub Actions (Recommended)

### Step 1: Configure Service Principals

The repository is already configured with service principals. Verify secrets are set:

```bash
gh secret list --repo NijTeck/epac-v2
```

**Required secrets:**
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### Step 2: Trigger Deployment

**Deploy to Dev Environment:**
```bash
gh workflow run "EPAC Dev Workflow" --repo NijTeck/epac-v2 --ref working-nist800-controls
```

**Deploy to Production:**
```bash
gh workflow run "EPAC Tenant Workflow" --repo NijTeck/epac-v2 --ref main
```

**Watch Progress:**
```bash
gh run watch
```

### Step 3: Verify Deployment

```bash
# Check policy assignments
az policy assignment list \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f" \
  --query "[?displayName=='NIST SP 800-53 Rev. 5'].{Name:name,Scope:scope}" -o table

# Check compliance
az policy state summarize \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f"
```

---

## Option 2: Deploy Locally

### Step 1: Clone and Setup

```bash
# Clone repository
git clone git@github.com:NijTeck/epac-v2.git
cd epac-v2

# Install EPAC module
Install-Module EnterprisePolicyAsCode -Scope CurrentUser
```

### Step 2: Login to Azure

```bash
# Login
az login

# Set subscription
az account set --subscription "120592c4-94bc-4ec2-b08f-de7f4055cfdf"

# Or use PowerShell
Connect-AzAccount
```

### Step 3: Build Deployment Plan

```powershell
# Build plan for dev environment
Build-DeploymentPlans `
  -DefinitionsRootFolder ".\Definitions" `
  -OutputFolder ".\Output" `
  -PacEnvironment "epac-dev"
```

### Step 4: Deploy Policies

```powershell
# Deploy policies
Deploy-PolicyPlan `
  -DefinitionsRootFolder ".\Definitions" `
  -InputFolder ".\Output" `
  -PacEnvironment "epac-dev"

# Deploy role assignments
Deploy-RolesPlan `
  -DefinitionsRootFolder ".\Definitions" `
  -InputFolder ".\Output" `
  -PacEnvironment "epac-dev"
```

---

## Configuration Files

### Key Files to Modify

**1. Policy Parameters** (`Definitions/policyAssignments/nist-800-53-parameters.csv`)
- Controls policy effects (Audit, Deny, etc.)
- Modify the `defaultEffect` column to change enforcement

**2. Assignment Scope** (`Definitions/policyAssignments/nist-800-53-assignments.jsonc`)
- Controls where policies are assigned
- Currently assigned to Tenant Root Group

**3. Global Settings** (`Definitions/global-settings.jsonc`)
- Azure tenant and deployment configuration
- Service principal settings

---

## Common Tasks

### Check Current Enforcement Status
```powershell
.\Scripts\Analyze-PolicyEnforcement.ps1
```

### Run Remediation
```powershell
.\Scripts\Start-NISTRemediation.ps1 -Environment TENANT -WaitForCompletion
```

### Change Policy Effects
Edit `Definitions/policyAssignments/nist-800-53-parameters.csv`:
```csv
displayName,defaultEffect
"Network Security Groups should be enabled",Deny
```

Then commit and push:
```bash
git add Definitions/policyAssignments/nist-800-53-parameters.csv
git commit -m "Update policy effects"
git push
```

### View Compliance Report
```bash
# Summary
az policy state summarize \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f"

# Details
az policy state list \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f" \
  --filter "complianceState eq 'NonCompliant'" -o table
```

---

## Troubleshooting

### Deployment Fails with Permission Error
```bash
# Verify service principal has required roles
az role assignment list \
  --assignee <service-principal-id> \
  --scope "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
```

**Required roles:**
- Resource Policy Contributor
- Role Based Access Control Administrator
- Reader

### No Policies Deployed
Check the assignment scope in `nist-800-53-assignments.jsonc` matches your management group:
```json
{
  "scope": {
    "tenant": ["/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"]
  }
}
```

### Policies Not Enforcing
Policies are in Audit mode by default. See [NIST-COMPLIANCE.md](NIST-COMPLIANCE.md) for enforcement instructions.

---

## Next Steps

1. **Monitor compliance** for 30-60 days in audit mode
2. **Review** [NIST-COMPLIANCE.md](NIST-COMPLIANCE.md) for enforcement options
3. **Set up** automated remediation workflows
4. **Plan** enforcement rollout strategy

## Support

- GitHub Issues: https://github.com/NijTeck/epac-v2/issues
- EPAC Documentation: https://aka.ms/epac
- Azure Policy Docs: https://aka.ms/azurepolicy