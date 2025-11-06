# NIST 800-53 Compliance Guide

Complete guide for NIST 800-53 Rev. 5 compliance implementation using Azure Policy as Code.

## Quick Status

**Current State:**
- ✅ 238 NIST 800-53 policies deployed
- ✅ Automated remediation configured
- ⚠️ 92.4% policies in Audit mode (reporting only)
- ⚠️ 1.7% policies in Enforcement mode

**Run this to check current status:**
```powershell
.\Scripts\Analyze-PolicyEnforcement.ps1
```

---

## Understanding Audit vs Enforcement Mode

### Current Configuration (Audit Mode)
Your policies are currently set to **report compliance issues** but NOT prevent or fix them:

- **Audit/AuditIfNotExists (92.4%)**: Reports non-compliance, takes no action
- **DeployIfNotExists/Modify (1.7%)**: Automatically fixes issues
- **Disabled (5.9%)**: Policy not evaluated

### What Audit Mode Means
- ✅ You get compliance reports
- ✅ Safe for initial deployment
- ❌ Non-compliant resources can still be created
- ❌ Existing violations remain unfixed

### What Enforcement Mode Would Do
- ✅ Blocks non-compliant resource creation (Deny effect)
- ✅ Automatically fixes issues (DeployIfNotExists/Modify effects)
- ⚠️ May disrupt existing workloads
- ⚠️ Requires careful planning

---

## Enforcement Capabilities

**89 policies (37.4%) can be switched to enforcement mode:**
- 85 policies support **Deny** (block non-compliant resources)
- 2 policies support **DeployIfNotExists** (auto-deploy fixes)
- 2 policies support **Modify** (auto-correct settings)

**Top Technical Controls Ready for Enforcement:**
- **SC-7**: Boundary Protection - 106 policies
- **AU-6**: Audit Review - 80 policies
- **AC-17**: Remote Access - 72 policies (11% already enforcing)
- **AU-12**: Audit Generation - 66 policies
- **AC-4**: Information Flow - 54 policies

---

## Automated Remediation

### Current Setup
Automated remediation is configured but limited to only 4 policies:

**How it Works:**
1. Policies with **DeployIfNotExists** or **Modify** effects automatically fix issues
2. Auto-remediation workflow runs after deployments
3. Manual remediation available via script

**Run Manual Remediation:**
```powershell
.\Scripts\Start-NISTRemediation.ps1 -Environment TENANT -WaitForCompletion
```

**Trigger Auto-Remediation Workflow:**
```bash
gh workflow run "Auto-Remediation for NIST 800-53" --ref working-nist800-controls
```

---

## Compliance Analysis

### Key Non-Compliance Areas
Based on recent analysis, these controls have the most violations:

1. **Audit and Accountability (AU)**: Diagnostic settings, log collection
2. **Incident Response (IR)**: Security Center, alerting
3. **System Integrity (SI)**: Vulnerability scanning, defender
4. **Access Control (AC)**: Network security, MFA, JIT access

### Checking Compliance Status

**Via Azure CLI:**
```bash
# Overall compliance summary
az policy state summarize \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f"

# List non-compliant resources
az policy state list \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f" \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[].{Resource:resourceId, Policy:policyDefinitionName}" -o table
```

**Via PowerShell:**
```powershell
# Get compliance summary
Get-AzPolicyStateSummary -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f"

# Get non-compliant resources
Get-AzPolicyState -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" `
  -Filter "ComplianceState eq 'NonCompliant'"
```

---

## Moving to Enforcement Mode

### ⚠️ Important Warnings

**Before enabling enforcement:**
1. Test in dev environment first
2. Identify resources that will be affected
3. Plan remediation for existing violations
4. Communicate with teams about potential disruptions
5. Have rollback plan ready

### Step 1: Analyze Impact

```powershell
# Run enforcement analysis
.\Scripts\Analyze-PolicyEnforcement.ps1

# Review which policies can enforce
Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" |
  Where-Object { $_.allowedEffects -match "Deny" } |
  Select-Object displayName, defaultEffect, allowedEffects
```

### Step 2: Enable Enforcement (Phased Approach)

**Option A: Enable for Specific Controls**
Edit `Definitions/policyAssignments/nist-800-53-parameters.csv` and change `defaultEffect` column:
- From: `Audit`
- To: `Deny` or `DeployIfNotExists` or `Modify`

**Example - Enable network security enforcement:**
```csv
displayName,defaultEffect,allowedEffects
"Network Security Groups should be enabled",Deny,"Deny,Audit,Disabled"
```

**Option B: Enable All Enforceable Policies**
```powershell
# Create script to update all to enforcement mode
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"
foreach ($row in $csv) {
  if ($row.allowedEffects -match "Deny") {
    $row.defaultEffect = "Deny"
  } elseif ($row.allowedEffects -match "DeployIfNotExists") {
    $row.defaultEffect = "DeployIfNotExists"
  } elseif ($row.allowedEffects -match "Modify") {
    $row.defaultEffect = "Modify"
  }
}
$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

### Step 3: Deploy Changes

**Commit and push:**
```bash
git add Definitions/policyAssignments/nist-800-53-parameters.csv
git commit -m "Enable enforcement mode for NIST 800-53 policies"
git push
```

**Deploy via GitHub Actions:**
- Workflow will automatically trigger on push to main
- Or manually trigger: `gh workflow run "EPAC Dev Workflow"`

### Step 4: Monitor and Remediate

**Monitor deployment:**
```bash
gh run watch
```

**Check for blocked resources:**
```bash
az policy state list \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f" \
  --filter "complianceState eq 'NonCompliant' and policyDefinitionAction eq 'deny'"
```

**Run remediation:**
```powershell
.\Scripts\Start-NISTRemediation.ps1 -WaitForCompletion
```

---

## Rollback Procedure

If enforcement causes issues:

### Quick Rollback - Change to Audit
```bash
# Checkout previous commit
git revert HEAD
git push

# Or manually change effects back to Audit in CSV
# Then commit and push
```

### Emergency Disable
```bash
# Disable policy assignment in Azure
az policy assignment delete \
  --name "NIST-800-53-Rev5" \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f"
```

---

## Cost Implications

**Current Cost (Audit Mode):**
- Azure Policy: Free for built-in policies
- Log Analytics (if configured): ~$2-5/GB

**Enforcement Mode Additional Costs:**
- Microsoft Defender for Cloud: ~$15/server/month
- Security Center Standard: ~$15/resource/month
- Additional Log Analytics ingestion: ~$2-5/GB

---

## Reference

### Key Files
- Policy Configuration: `Definitions/policyAssignments/nist-800-53-parameters.csv`
- Assignment Config: `Definitions/policyAssignments/nist-800-53-assignments.jsonc`
- Global Settings: `Definitions/global-settings.jsonc`

### Useful Scripts
- `Scripts/Analyze-PolicyEnforcement.ps1` - Check enforcement status
- `Scripts/Start-NISTRemediation.ps1` - Run manual remediation
- `Scripts/update-for-remediation.ps1` - Update CSV for auto-remediation

### GitHub Workflows
- `.github/workflows/epac-dev-workflow.yml` - Dev deployment
- `.github/workflows/epac-tenant-workflow.yml` - Production deployment
- `.github/workflows/auto-remediation.yml` - Auto-remediation

### Azure Resources
- Tenant Root Group: `e1f3e196-aa55-4709-9c55-0e334c0b444f`
- Dev Subscription: `120592c4-94bc-4ec2-b08f-de7f4055cfdf`
- Prod Subscription: `6dc7cfa2-0332-4740-98b6-bac9f1a23de9`

---

## Recommended Next Steps

1. **Keep in Audit Mode** for 30-60 days to establish baseline
2. **Review compliance reports** weekly to understand violations
3. **Fix critical violations** manually first
4. **Enable enforcement gradually** starting with low-risk controls
5. **Monitor impact** closely during rollout
6. **Adjust exclusions** as needed for legitimate exceptions

For deployment instructions, see [QUICKSTART.md](QUICKSTART.md)