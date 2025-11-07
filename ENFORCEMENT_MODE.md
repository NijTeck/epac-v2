# NIST 800-53 Enforcement Mode Guide

This guide explains how to deploy and manage NIST 800-53 policies in **enforcement mode** (Deny, DeployIfNotExists, Modify, Append) rather than audit mode.

## Overview

**Enforcement mode** means policies actively prevent or remediate non-compliance, rather than just reporting it.

### Policy Effects

| Effect | Type | Behavior | Use Case |
|--------|------|----------|----------|
| **Deny** | Preventive | Blocks non-compliant resource creation | Prevent security violations |
| **DeployIfNotExists** | Detective + Remediation | Auto-deploys missing configurations | Auto-enable security features |
| **Modify** | Corrective | Auto-corrects configuration drift | Fix misconfigurations |
| **Append** | Additive | Adds required properties/tags | Enforce tagging standards |
| **Audit** | Detective | Reports non-compliance only | Informational monitoring |

## Enforcement Effect Decision Tree

```
Can the control prevent non-compliance?
├─ Yes → Can it block resource creation?
│  ├─ Yes → Use Deny
│  │  Example: "Storage accounts should use private link"
│  │  Effect: Blocks creation of storage account without private endpoint
│  │
│  └─ No → Can it deploy missing configuration?
│     ├─ Yes → Use DeployIfNotExists
│     │  Example: "Diagnostic settings should be enabled"
│     │  Effect: Automatically creates diagnostic settings if missing
│     │
│     └─ No → Can it modify existing configuration?
│        ├─ Yes → Use Modify
│        │  Example: "VMs should have monitoring agent"
│        │  Effect: Installs agent on existing VMs
│        │
│        └─ No → Use Append
│           Example: "Resources should have required tags"
│           Effect: Adds tags to resources
│
└─ No → Is it detective only?
   └─ Yes → Use Audit
      Example: "Review access control lists"
      Effect: Reports for manual review
```

## Current Enforcement Status

Based on the latest deployment:

- **High-Priority Controls** (AC, SC, IA): Enforcement mode enabled for production
- **Medium-Priority Controls** (AU, CM): Enforcement mode enabled for production
- **All Controls**: Audit mode for non-production (for testing)

### Files Updated

1. **nist-800-53-parameters.csv**: `prodEffect` column updated to enforcement effects
2. **nist-control-mapping.csv**: Tracks which controls use which enforcement effects
3. **policy-enforcement-categorization.csv**: Lists all policies by enforcement capability

## Testing Enforcement Policies

### Test Deny Policies

**Purpose**: Verify non-compliant resources are blocked

**Steps**:
1. Identify a Deny policy (e.g., "API Management should use virtual network")
2. Attempt to create non-compliant resource via Azure Portal or CLI
3. Verify creation is blocked with clear error message
4. Verify error message references the policy

**Example**:
```powershell
# This should be blocked if policy is enforced
New-AzApiManagement -ResourceGroupName "test-rg" `
    -Name "test-apim" `
    -Location "eastus" `
    -Organization "Test" `
    -AdminEmail "admin@test.com" `
    -Sku "Developer"
    # Missing: -VirtualNetwork parameter

# Expected: Deployment blocked by policy
```

### Test DeployIfNotExists Policies

**Purpose**: Verify missing configurations are auto-deployed

**Steps**:
1. Identify a DINE policy (e.g., "Diagnostic settings should be enabled")
2. Create resource without the required configuration
3. Wait for policy evaluation (up to 30 minutes)
4. Verify remediation task is created automatically
5. Verify configuration is deployed

**Example**:
```powershell
# Create storage account without diagnostic settings
New-AzStorageAccount -ResourceGroupName "test-rg" `
    -Name "teststorage123" `
    -Location "eastus" `
    -SkuName "Standard_LRS"

# Wait for policy evaluation
Start-Sleep -Seconds 1800  # 30 minutes

# Check for remediation task
Get-AzPolicyRemediation -ManagementGroupName "your-mg" | 
    Where-Object { $_.PolicyAssignmentId -like "*nist*" }

# Verify diagnostic settings were created
Get-AzDiagnosticSetting -ResourceId "/subscriptions/.../teststorage123"
```

### Test Modify Policies

**Purpose**: Verify configurations are auto-corrected

**Steps**:
1. Identify a Modify policy
2. Create resource with incorrect configuration
3. Wait for policy evaluation
4. Verify configuration is automatically corrected

### Test Append Policies

**Purpose**: Verify properties are automatically added

**Steps**:
1. Identify an Append policy (e.g., required tags)
2. Create resource without required properties
3. Verify properties are automatically added

## Deployment Procedure

### Phase 1: Pre-Deployment Validation

**Checklist**:
- [ ] Backup of audit-mode parameters exists (`nist-800-53-parameters-audit-mode.csv.bak`)
- [ ] Control mapping CSV reviewed (`nist-control-mapping.csv`)
- [ ] Enforcement categorization reviewed (`policy-enforcement-categorization.csv`)
- [ ] Compliance coverage report reviewed (`nist-compliance-coverage.csv`)
- [ ] Stakeholders notified of enforcement mode deployment
- [ ] Exemption process documented and communicated

### Phase 2: Deploy to Dev Environment

**Purpose**: Test enforcement policies in non-production

**Steps**:
1. Deploy to epac-dev with current configuration (nonprodEffect = Audit)
2. Manually test enforcement effects:
   - Test Deny policies by attempting non-compliant deployments
   - Test DINE policies by creating resources without required configs
   - Verify remediation tasks are created
3. Monitor for 48 hours:
   - Check for blocked legitimate deployments
   - Review remediation task success rate
   - Identify any issues

**Commands**:
```powershell
# Local deployment
Build-DeploymentPlans -PacEnvironmentSelector "epac-dev"
Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev"
Deploy-RolesPlan -PacEnvironmentSelector "epac-dev"

# Or via GitHub Actions
git checkout -b feature/enforcement-mode-testing
git push origin feature/enforcement-mode-testing
# Workflow automatically deploys to epac-dev
```

### Phase 3: Enable Enforcement in Production

**Purpose**: Activate enforcement mode for production

**Steps**:
1. Update `nonprodEffect` column to match `prodEffect` (optional)
2. Commit changes to main branch
3. Deploy via GitHub Actions with approval gates
4. Monitor compliance dashboard

**Commands**:
```powershell
# Update nonprod to match prod (optional)
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"
foreach ($policy in $csv) {
    if ($policy.prodEffect -in @("Deny", "DeployIfNotExists", "Modify", "Append")) {
        $policy.nonprodEffect = $policy.prodEffect
    }
}
$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation

# Commit and deploy
git add Definitions/
git commit -m "feat: enable enforcement mode for nonprod"
git push origin main
```

### Phase 4: Post-Deployment Monitoring

**Monitor for 7 days**:
- [ ] Check Azure Policy compliance dashboard daily
- [ ] Review blocked deployments (Deny policies)
- [ ] Review remediation tasks (DINE policies)
- [ ] Check for false positives
- [ ] Process exemption requests

**Monitoring Commands**:
```powershell
# Check compliance status
Get-AzPolicyStateSummary -ManagementGroupName "your-mg"

# List non-compliant resources
Get-AzPolicyState -ManagementGroupName "your-mg" -Filter "ComplianceState eq 'NonCompliant'"

# Check remediation tasks
Get-AzPolicyRemediation -ManagementGroupName "your-mg" | 
    Where-Object { $_.PolicyAssignmentId -like "*nist*" }

# View blocked deployments (Activity Log)
Get-AzLog -ResourceProvider "Microsoft.Authorization" | 
    Where-Object { $_.Status.Value -eq "Failed" -and $_.SubStatus.Value -like "*policy*" }
```

## Rollback Procedures

### Emergency Rollback (Disable Enforcement)

If enforcement causes critical issues:

```powershell
# Option 1: Set all assignments to DoNotEnforce mode (fastest)
Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" } | 
    ForEach-Object {
        Set-AzPolicyAssignment -Id $_.ResourceId -EnforcementMode DoNotEnforce
    }

# Option 2: Restore audit-mode parameters and redeploy
Copy-Item "Definitions/policyAssignments/nist-800-53-parameters-audit-mode.csv.bak" `
    "Definitions/policyAssignments/nist-800-53-parameters.csv" -Force

# Redeploy
Build-DeploymentPlans -PacEnvironmentSelector "tenant"
Deploy-PolicyPlan -PacEnvironmentSelector "tenant"
```

### Selective Rollback (Specific Policies)

If specific policies cause issues:

```powershell
# Revert specific policy to Audit mode
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"
$csv | Where-Object { $_.name -eq "<policy-guid>" } | ForEach-Object {
    $_.prodEffect = "Audit"
}
$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation

# Redeploy
Build-DeploymentPlans -PacEnvironmentSelector "tenant"
Deploy-PolicyPlan -PacEnvironmentSelector "tenant"
```

## Common Issues and Solutions

### Issue: Legitimate Deployment Blocked

**Symptom**: Deny policy blocks valid resource deployment

**Solution**:
1. Review policy requirements
2. If deployment is legitimate, create exemption (see EXEMPTIONS.md)
3. If policy is too restrictive, adjust parameters or revert to Audit

### Issue: Remediation Task Fails

**Symptom**: DeployIfNotExists policy creates remediation task but it fails

**Solution**:
1. Check managed identity has required permissions
2. Review remediation task error details:
   ```powershell
   Get-AzPolicyRemediation -Name "<task-name>" -ManagementGroupName "your-mg" | 
       Select-Object -ExpandProperty DeploymentSummary
   ```
3. Manually remediate if needed
4. Update policy parameters if issue is systemic

### Issue: Too Many Non-Compliant Resources

**Symptom**: Hundreds of resources flagged as non-compliant

**Solution**:
1. Prioritize by risk (focus on high-priority controls first)
2. Create bulk remediation tasks:
   ```powershell
   Start-AzPolicyRemediation -Name "bulk-remediation" `
       -PolicyAssignmentId "<assignment-id>" `
       -ManagementGroupName "your-mg"
   ```
3. Consider phased enforcement (start with new resources only)

## Best Practices

1. **Test in Dev First**: Always validate enforcement in epac-dev before production
2. **Monitor Closely**: Watch compliance dashboard for first 7 days after enforcement
3. **Document Exemptions**: Track all exemptions with business justification
4. **Regular Reviews**: Review enforcement effectiveness quarterly
5. **Communicate Changes**: Notify teams before enabling enforcement mode
6. **Have Rollback Plan**: Keep audit-mode backup and know rollback procedures
7. **Gradual Rollout**: Enable enforcement for high-priority controls first

## Enforcement Mode Metrics

Track these metrics to measure enforcement effectiveness:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Blocked Deployments | < 5% false positives | Review Activity Log for policy denials |
| Remediation Success Rate | > 95% | Check remediation task completion rate |
| Time to Remediation | < 24 hours | Monitor remediation task duration |
| Exemption Rate | < 10% of policies | Count exemptions vs. total policies |
| Compliance Rate | > 90% | Azure Policy compliance dashboard |

## Support

For issues with enforcement mode:
- Review this guide and troubleshooting section
- Check EXEMPTIONS.md for exemption process
- Check REMEDIATION.md for remediation guidance
- Open GitHub issue for bugs or questions
