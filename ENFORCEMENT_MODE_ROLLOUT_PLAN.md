# NIST 800-53 Enforcement Mode Rollout Plan

## Executive Summary

This document outlines the phased approach to transition NIST 800-53 policies from **Audit mode** (monitoring only) to **Enforcement mode** (blocking/remediating non-compliant resources).

**Current State**: All 238 NIST 800-53 policies configured in Audit/AuditIfNotExists mode
**Target State**: Critical policies enforced via Deny/DeployIfNotExists effects
**Timeline**: 8-12 weeks for full rollout
**Risk Level**: Managed through phased approach

---

## Phase 0: Preparation (Week 1-2)

### ✅ Completed
- [x] Fill 117 empty policy effects in CSV
- [x] Add managed identity configuration
- [x] Create role assignment script
- [x] Backup original configuration

### 🔄 To Complete
- [ ] Review current compliance baseline in Azure Portal
- [ ] Document current non-compliant resources
- [ ] Identify business-critical workloads to exclude (exemptions)
- [ ] Set up monitoring/alerting for policy changes
- [ ] Communicate rollout plan to stakeholders

### Deliverables
- Compliance baseline report
- Exemption requirements list
- Stakeholder communication sent
- Rollback procedures documented

---

## Phase 1: Dev Environment Testing (Week 3-4)

### Objective
Test enforcement effects in `epac-dev` environment with low-risk policies.

### Actions

#### 1.1 Deploy Current Configuration to Dev
```powershell
# Deploy audit mode to dev first
Build-DeploymentPlans -PacEnvironmentSelector "epac-dev" -InformationAction Continue
Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue

# Wait 5-10 minutes
./Scripts/Assign-PolicyManagedIdentityRoles.ps1 -PacEnvironmentSelector epac-dev -WaitForIdentity 5

Deploy-RolesPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue
```

#### 1.2 Enable 5 Low-Risk Enforcement Policies

Update these policies in `nist-800-53-parameters.csv` (change prodEffect to "Deny" for epac-dev testing):

| Policy Name | Control | Current | New (Dev) | Risk |
|-------------|---------|---------|-----------|------|
| Storage accounts should restrict network access | SC-7 | Audit | Deny | LOW |
| Storage accounts should use private link | AC-4, SC-7 | AuditIfNotExists | Deny | LOW |
| Public network access should be disabled for MySQL | AC-4, SC-7 | Audit | Deny | LOW |
| Public network access should be disabled for PostgreSQL | AC-4, SC-7 | Audit | Deny | LOW |
| API Management should use virtual network | AC-4, SC-7 | Audit | Deny | LOW |

**Note**: For CSV, you need a strategy to apply different effects to dev vs prod. Consider:
- Option A: Use separate CSV files (nist-800-53-parameters-dev.csv, nist-800-53-parameters-prod.csv)
- Option B: Use parameter overrides in assignments file
- Option C: Test in dev, then promote to prod manually

#### 1.3 Test and Validate
- Deploy updated configuration to dev
- Attempt to create non-compliant resources (should be blocked)
- Verify deny effects work as expected
- Document any false positives
- Create exemptions for legitimate cases

### Success Criteria
- ✅ All 5 policies successfully block non-compliant resources
- ✅ No false positives or < 5% false positive rate
- ✅ Exemption process tested and validated
- ✅ Rollback procedure tested

---

## Phase 2: Production Pilot - Network Security (Week 5-6)

### Objective
Deploy 10-15 network security policies to production in enforcement mode.

### Policy Categories to Enforce

#### 2.1 Network Isolation Policies (8 policies)
```csv
# Update in nist-800-53-parameters.csv - change prodEffect to Deny
- Storage accounts should restrict network access (SC-7)
- Storage accounts should use private link (AC-4, SC-7)
- App Configuration should use private link (AC-4, SC-7)
- Azure Cosmos DB should use private link (AC-4, SC-7)
- Azure Key Vault should use private link (AC-4, SC-7)
- Azure SQL Database should use private link (AC-4, SC-7)
- Public network access on Azure SQL Database should be disabled (AC-4)
- Public network access should be disabled for MySQL (AC-4)
```

#### 2.2 TLS/Encryption in Transit (7 policies)
```csv
# Update in nist-800-53-parameters.csv - change prodEffect to Deny
- App Service apps should only be accessible over HTTPS (SC-8)
- Function apps should only be accessible over HTTPS (SC-8)
- Storage accounts should enable secure transfer (SC-8)
- Redis Cache should only use SSL connections (SC-8)
- API Management should use latest TLS version (SC-8)
- App Service should use latest TLS version (SC-8)
- Function apps should use latest TLS version (SC-8)
```

### Deployment Process

```powershell
# 1. Update CSV with Deny effects for selected policies
# 2. Create exemptions for known legacy resources (if needed)
# 3. Generate and review plan
Build-DeploymentPlans -PacEnvironmentSelector "tenant" -InformationAction Continue

# 4. Review plan carefully - check for unexpected changes
Get-ChildItem ./Output/tenant -Recurse

# 5. Deploy to production (requires approval in GitHub Actions)
Deploy-PolicyPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
Deploy-RolesPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
```

### Monitoring (Week 6)
- Monitor deny events in Azure Activity Log
- Track exemption requests
- Review compliance scores daily
- Communicate with affected teams

### Success Criteria
- ✅ < 10 exemption requests per week
- ✅ No production incidents caused by policies
- ✅ Compliance score improves by 10-15%
- ✅ Stakeholder feedback positive

---

## Phase 3: Expand Enforcement - Compute & Identity (Week 7-8)

### Objective
Add enforcement for compute, identity, and access control policies.

### Policy Categories

#### 3.1 Virtual Machine Security (12 policies)
```csv
# Moderate risk - test thoroughly
- VMs should have Endpoint Protection installed (DeployIfNotExists/AuditIfNotExists)
- VMs should have disk encryption enabled (Audit → AuditIfNotExists, then Deny)
- VMs should use managed disks (Deny)
- VMs should not have public IPs (Deny)
- Just-In-Time network access should be enabled (AuditIfNotExists)
```

#### 3.2 Identity & Access Management (8 policies)
```csv
# Lower risk - mostly audit/report
- MFA should be enabled on accounts with owner permissions (AuditIfNotExists)
- MFA should be enabled on accounts with write permissions (AuditIfNotExists)
- External accounts with owner permissions should be removed (AuditIfNotExists)
- Deprecated accounts should be removed (AuditIfNotExists)
```

### Deployment Process
- Same as Phase 2
- Add 2-week observation period before expanding further

---

## Phase 4: Remediation Policies (Week 9-10)

### Objective
Enable automatic remediation for configuration drift.

### DeployIfNotExists Policies to Enable

These policies will automatically deploy missing configurations:

```csv
# Update in nist-800-53-parameters.csv - enable DINE
- Deploy Diagnostic Settings for Storage Accounts to Log Analytics (DeployIfNotExists)
- Deploy Diagnostic Settings for Key Vaults to Log Analytics (DeployIfNotExists)
- Deploy Advanced Data Security on SQL servers (DeployIfNotExists)
- Deploy Azure Security Center for Azure SQL Database (DeployIfNotExists)
- Deploy Log Analytics Agent for Linux VMs (DeployIfNotExists)
- Deploy Log Analytics Agent for Windows VMs (DeployIfNotExists)
```

### Key Requirements
✅ Managed identity configured (completed in Phase 0)
✅ Role assignments in place (Contributor, Log Analytics Contributor, etc.)
⚠️ Test remediation tasks carefully - they modify resources!

### Testing Remediation

```powershell
# After deploying DINE policies, trigger remediation
$assignment = Get-AzPolicyAssignment -Name "nist-800-53-r5" -Scope "<deployment-root-scope>"

# Start remediation for specific policy
Start-AzPolicyRemediation `
    -Name "remediate-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
    -PolicyAssignmentId $assignment.PolicyAssignmentId `
    -PolicyDefinitionReferenceId "<policy-reference-id>" `
    -ResourceGroupName "<test-rg>"

# Monitor remediation
Get-AzPolicyRemediation -Name "remediate-*" | Format-Table
```

---

## Phase 5: Full Enforcement - All Categories (Week 11-12)

### Objective
Enable enforcement for all applicable NIST 800-53 policies.

### Remaining Categories
- Data Protection & Encryption (15 policies)
- Monitoring & Logging (20 policies)
- Backup & DR (8 policies)
- Kubernetes & Container Security (25 policies)

### Process
1. Update CSV in batches of 10-15 policies per week
2. Deploy, monitor, adjust
3. Create exemptions as needed
4. Document lessons learned

---

## Exemption Management

### When to Grant Exemptions

✅ **Valid Reasons:**
- Legacy systems with documented migration plan
- Business-critical workloads with compensating controls
- Technical limitations (e.g., vendor SaaS integration)
- Temporary exemption during transition period (max 90 days)

❌ **Invalid Reasons:**
- "Too hard to fix"
- No business justification
- Indefinite exemptions without review

### Creating Exemptions

Create exemption files in `Definitions/policyExemptions/`:

```jsonc
{
    "$schema": "https://raw.githubusercontent.com/Azure/enterprise-azure-policy-as-code/main/Schemas/policy-exemption-schema.json",
    "exemptions": [
        {
            "name": "legacy-app-https-exemption",
            "displayName": "Legacy App - HTTPS Requirement Exemption",
            "description": "Legacy application does not support HTTPS. Migration planned for Q3 2025.",
            "exemptionCategory": "Waiver",
            "scope": "/subscriptions/<sub-id>/resourceGroups/legacy-rg",
            "policyAssignmentName": "nist-800-53-r5",
            "policyDefinitionReferenceIds": [
                "a4af4a39-4135-47fb-b175-47fbdf85311d"
            ],
            "expiresOn": "2025-09-30",
            "metadata": {
                "approvedBy": "CISO",
                "approvalDate": "2025-01-15",
                "businessJustification": "Legacy app required for Q1 operations",
                "compensatingControls": "Network-level TLS termination via Application Gateway"
            }
        }
    ]
}
```

Deploy exemptions:
```powershell
Build-DeploymentPlans -PacEnvironmentSelector "tenant" -InformationAction Continue
Deploy-ExemptionsPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
```

---

## Monitoring & Compliance

### Daily Checks (Automated)
- Policy compliance scores
- New deny events in Activity Log
- Exemption expiration warnings

### Weekly Reviews
- Compliance trends
- Exemption requests queue
- False positive analysis
- Incident reports related to policies

### Monthly Reviews
- Overall compliance posture
- Policy effectiveness analysis
- Update rollout plan based on findings
- Executive summary report

### Azure Portal Navigation
1. **Policy Compliance**: Portal → Policy → Compliance → Filter: "NIST SP 800-53"
2. **Deny Events**: Portal → Activity Log → Filter: "Policy" + "Deny"
3. **Remediation Tasks**: Portal → Policy → Remediation

---

## Rollback Procedures

### Emergency Rollback (Production Issue)

If a policy causes production issues:

```powershell
# Option 1: Disable specific policy quickly via CSV
# Set prodEffect to "Disabled" for problematic policy
# Then deploy:
Build-DeploymentPlans -PacEnvironmentSelector "tenant"
Deploy-PolicyPlan -PacEnvironmentSelector "tenant"

# Option 2: Create emergency exemption
# Add exemption to Definitions/policyExemptions/emergency-exemptions.jsonc
Build-DeploymentPlans -PacEnvironmentSelector "tenant"
Deploy-ExemptionsPlan -PacEnvironmentSelector "tenant"

# Option 3: Full rollback to audit mode
# Restore nist-800-53-parameters.csv from backup
git checkout HEAD~1 Definitions/policyAssignments/nist-800-53-parameters.csv
Build-DeploymentPlans -PacEnvironmentSelector "tenant"
Deploy-PolicyPlan -PacEnvironmentSelector "tenant"
```

### Validation After Rollback
- Verify policy shows "Disabled" or "Audit" effect in Portal
- Confirm resources can be created/modified
- Document incident and root cause
- Update plan to prevent recurrence

---

## Success Metrics

### Phase 1 (Dev Testing)
- ✅ 5 policies tested in enforcement mode
- ✅ 0 production incidents (dev only)
- ✅ Rollback tested successfully

### Phase 2 (Production Pilot)
- ✅ 15 network policies enforced
- ✅ Compliance score: +10-15%
- ✅ < 10 exemptions requested
- ✅ < 2 incidents (resolved within 24h)

### Phase 3-4 (Expansion)
- ✅ 50+ policies enforced
- ✅ Compliance score: +25-35%
- ✅ < 20 total exemptions
- ✅ < 5 incidents per phase

### Phase 5 (Full Enforcement)
- ✅ 150+ policies enforced (Deny/DINE)
- ✅ Compliance score: 80%+
- ✅ < 30 total active exemptions
- ✅ 0 major incidents

---

## Risk Mitigation

### High-Risk Policies
These policies should be enabled **last** and with extensive testing:

- Deny VM creation without encryption
- Deny public IPs on VMs
- Deny unmanaged disks
- Deny SQL databases without encryption

**Strategy**: Use AuditIfNotExists for 4+ weeks, analyze impact, then enable Deny.

### Communication Plan
- **Week before each phase**: Email to stakeholders
- **Day of deployment**: Teams/Slack announcement
- **Weekly updates**: Compliance dashboard shared
- **Monthly**: Executive summary to leadership

---

## Tools & Scripts

### Useful PowerShell Commands

```powershell
# Check current compliance
Get-AzPolicyState -Filter "PolicyAssignmentName eq 'nist-800-53-r5'" |
    Group-Object ComplianceState |
    Select-Object Name, Count

# List recent deny events
Get-AzLog -StartTime (Get-Date).AddDays(-7) -Status "Failed" |
    Where-Object { $_.Authorization.Action -like "*policyEvents*" } |
    Select-Object EventTimestamp, ResourceId, OperationName

# Export compliance report
$states = Get-AzPolicyState -PolicyAssignmentName "nist-800-53-r5"
$states | Export-Csv -Path "compliance-report-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation

# List all exemptions
Get-AzPolicyExemption | Where-Object { $_.PolicyAssignmentId -like "*nist-800-53-r5*" } |
    Format-Table Name, ExemptionCategory, ExpiresOn
```

---

## Next Steps

1. ✅ **Complete Phase 0**: Review compliance baseline, document exemptions needed
2. 🔄 **Start Phase 1**: Deploy to dev, test 5 low-risk policies
3. ⏭️ **Schedule Phase 2**: Set production pilot date (4+ weeks out)
4. 📋 **Document everything**: Keep detailed notes of issues/learnings

---

## Contact & Support

- **Policy Questions**: Open GitHub issue
- **Exemption Requests**: Submit via [your approval process]
- **Incidents**: Follow standard incident response procedures

---

## Appendix A: Policy Effect Reference

| Effect | Behavior | When to Use |
|--------|----------|-------------|
| **Audit** | Log non-compliance | Initial discovery, low-risk monitoring |
| **AuditIfNotExists** | Log if resource/config missing | Check for missing configs (e.g., encryption) |
| **Deny** | Block non-compliant resource creation | Enforce hard requirements |
| **DeployIfNotExists** | Auto-deploy missing configs | Remediate configuration drift |
| **Modify** | Modify resource properties | Auto-fix specific properties (e.g., tags) |
| **Disabled** | Don't evaluate policy | Temporary disable or not applicable |

---

## Appendix B: CSV Update Examples

### Example 1: Change Single Policy to Deny
```csv
# Before
"a4af4a39-4135-47fb-b175-47fbdf85311d",...,"Audit","Audit",...

# After (Prod only)
"a4af4a39-4135-47fb-b175-47fbdf85311d",...,"Deny","Audit",...
```

### Example 2: Enable Remediation
```csv
# Before
"7796937f-307b-4598-941c-67d3a05ebfe7",...,"AuditIfNotExists","AuditIfNotExists",...

# After (Enable DINE)
"7796937f-307b-4598-941c-67d3a05ebfe7",...,"DeployIfNotExists","DeployIfNotExists",...
```

---

**Document Version**: 1.0
**Last Updated**: 2025-11-05
**Owner**: Platform Engineering / Cloud Security Team
