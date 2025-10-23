# NIST 800-53 Deployment Guide

This guide provides step-by-step instructions and checklists for deploying NIST 800-53 policies using EPAC.

## Pre-Deployment Checklist

Before deploying, ensure all prerequisites are met:

### Azure Configuration

- [ ] Azure tenant ID identified
- [ ] Management groups created and configured:
  - [ ] Dev environment management group
  - [ ] Production management group
  - [ ] Non-production management group
- [ ] Service principals created with required permissions
- [ ] Federated credentials configured for GitHub OIDC

### Repository Configuration

- [ ] `Definitions/global-settings.jsonc` updated with:
  - [ ] Correct tenant ID
  - [ ] Correct management group IDs
  - [ ] Correct managed identity location (Azure region)
- [ ] `Definitions/policyAssignments/nist-800-53-assignments.jsonc` updated with:
  - [ ] Correct management group scopes for Prod
  - [ ] Correct management group scopes for Nonprod
- [ ] `Definitions/policyAssignments/nist-800-53-parameters.csv` reviewed:
  - [ ] Policy effects set appropriately (start with Audit)
  - [ ] Parameters configured for your environment

### GitHub Configuration

- [ ] GitHub environments created (EPAC-DEV, TENANT-PLAN, TENANT-DEPLOY-POLICY, TENANT-DEPLOY-ROLES)
- [ ] Environment secrets configured (AZURE_CLIENT_ID, AZURE_TENANT_ID)
- [ ] Required reviewers added to production environments
- [ ] Branch protection rules enabled on `main`
- [ ] GitHub Actions enabled

### Local Development Setup (if using local deployment)

- [ ] PowerShell 7.0+ installed
- [ ] Azure PowerShell module installed: `Install-Module Az`
- [ ] EPAC PowerShell module installed: `Install-Module EnterprisePolicyAsCode`
- [ ] Azure authentication configured

## Deployment Workflow

### Phase 1: Initial Dev Deployment

Deploy to epac-dev environment first to validate configuration.

#### Using GitHub Actions

1. **Create feature branch**:
   ```bash
   git checkout -b feature/initial-nist-deployment
   ```

2. **Verify configuration files** are updated (see Pre-Deployment Checklist)

3. **Commit and push**:
   ```bash
   git add Definitions/
   git commit -m "feat: initial NIST 800-53 configuration"
   git push origin feature/initial-nist-deployment
   ```

4. **Monitor GitHub Actions**:
   - Navigate to **Actions** tab
   - Watch "EPAC Dev Workflow" execution
   - Verify all jobs complete successfully

5. **Review deployment**:
   - [ ] Plan job completed
   - [ ] Deploy Policy job completed
   - [ ] Deploy Roles job completed
   - [ ] No errors in logs

#### Using Local Deployment

1. **Authenticate to Azure**:
   ```powershell
   Connect-AzAccount -Tenant <YOUR-TENANT-ID>
   ```

2. **Generate plan**:
   ```powershell
   Build-DeploymentPlans -PacEnvironmentSelector "epac-dev" -InformationAction Continue
   ```

3. **Review plan files**:
   ```powershell
   # View policy plan
   Get-Content ./Output/policy-plan.json | ConvertFrom-Json | ConvertTo-Json -Depth 10

   # View roles plan
   Get-Content ./Output/roles-plan.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
   ```

4. **Deploy policies**:
   ```powershell
   Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue
   ```

5. **Deploy roles**:
   ```powershell
   Deploy-RolesPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue
   ```

### Phase 2: Validate Dev Deployment

After deployment to epac-dev, validate the configuration.

#### Azure Portal Validation

1. **Navigate to Azure Policy**:
   - Open Azure Portal
   - Search for "Policy"
   - Click "Policy" service

2. **Verify Policy Assignments**:
   - Click "Assignments"
   - Filter by management group (your dev MG)
   - Verify assignments exist:
     - [ ] `pr-nist-800-53-r5` (Prod scope)
     - [ ] `np-nist-800-53-r5` (Nonprod scope)

3. **Check Assignment Details**:
   - Click on each assignment
   - Verify:
     - [ ] Display name is correct
     - [ ] Description is correct
     - [ ] Scope is correct management group
     - [ ] Parameters are applied
     - [ ] Managed identity is created

4. **Review Compliance**:
   - Click "Compliance" in Policy menu
   - Find NIST 800-53 assignments
   - Note: Compliance evaluation takes 30-60 minutes initially
   - [ ] Assignments show "Not started" or "In progress" (normal for new deployments)

#### PowerShell Validation

```powershell
# List NIST 800-53 assignments
Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" } | 
    Select-Object Name, DisplayName, Scope

# Check managed identities
Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" } | 
    Select-Object Name, @{N='IdentityType';E={$_.Identity.Type}}, @{N='PrincipalId';E={$_.Identity.PrincipalId}}

# View role assignments for managed identities
$assignments = Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" }
foreach ($assignment in $assignments) {
    if ($assignment.Identity.PrincipalId) {
        Write-Host "Role assignments for $($assignment.Name):"
        Get-AzRoleAssignment -ObjectId $assignment.Identity.PrincipalId | 
            Select-Object RoleDefinitionName, Scope
    }
}
```

### Phase 3: Production Deployment

After validating dev deployment, deploy to production.

#### Using GitHub Actions

1. **Create Pull Request**:
   ```bash
   # Ensure you're on your feature branch
   git checkout feature/initial-nist-deployment
   
   # Push any final changes
   git push origin feature/initial-nist-deployment
   ```

2. **Open PR on GitHub**:
   - Navigate to repository
   - Click "Pull requests" > "New pull request"
   - Base: `main`, Compare: `feature/initial-nist-deployment`
   - Click "Create pull request"
   - Add description explaining the deployment

3. **Review Plan**:
   - Wait for "EPAC Dev Workflow" to complete (if not already)
   - Review workflow logs for any issues
   - Verify dev deployment is successful

4. **Merge PR**:
   - Get required approvals (if branch protection enabled)
   - Click "Merge pull request"
   - Click "Confirm merge"

5. **Monitor Production Deployment**:
   - Navigate to **Actions** tab
   - Watch "EPAC Tenant Workflow" execution
   - Workflow will pause at approval gates

6. **Approve Policy Deployment**:
   - Workflow pauses at "Deploy tenant Policy Changes"
   - Click "Review deployments"
   - Review the plan output in logs
   - Select "TENANT-DEPLOY-POLICY"
   - Click "Approve and deploy"

7. **Approve Roles Deployment**:
   - Workflow pauses at "Deploy tenant Role Changes"
   - Click "Review deployments"
   - Review the role assignments
   - Select "TENANT-DEPLOY-ROLES"
   - Click "Approve and deploy"

8. **Verify Completion**:
   - [ ] All jobs completed successfully
   - [ ] No errors in logs

#### Using Local Deployment

1. **Generate production plan**:
   ```powershell
   Build-DeploymentPlans -PacEnvironmentSelector "tenant" -InformationAction Continue
   ```

2. **Review plan carefully**:
   ```powershell
   # Review policy changes
   $policyPlan = Get-Content ./Output/policy-plan.json | ConvertFrom-Json
   
   Write-Host "New Assignments: $($policyPlan.policyAssignments.new.Count)"
   Write-Host "Updated Assignments: $($policyPlan.policyAssignments.update.Count)"
   Write-Host "Deleted Assignments: $($policyPlan.policyAssignments.delete.Count)"
   
   # Review role changes
   $rolesPlan = Get-Content ./Output/roles-plan.json | ConvertFrom-Json
   
   Write-Host "New Role Assignments: $($rolesPlan.roleAssignments.new.Count)"
   Write-Host "Deleted Role Assignments: $($rolesPlan.roleAssignments.delete.Count)"
   ```

3. **Get approval** from stakeholders (show them the plan output)

4. **Deploy to production**:
   ```powershell
   # Deploy policies
   Deploy-PolicyPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
   
   # Deploy roles
   Deploy-RolesPlan -PacEnvironmentSelector "tenant" -InformationAction Continue
   ```

### Phase 4: Post-Deployment Validation

After production deployment, validate the configuration.

#### Immediate Validation

- [ ] Policy assignments created in production management groups
- [ ] Managed identities created for assignments
- [ ] Role assignments created for managed identities
- [ ] No errors in deployment logs

#### Compliance Validation (after 30-60 minutes)

1. **Check Compliance Status**:
   - Navigate to Azure Policy > Compliance
   - Filter by NIST 800-53 assignments
   - [ ] Compliance evaluation has started
   - [ ] Resources are being evaluated

2. **Review Non-Compliant Resources**:
   - Click on assignment to see details
   - Review non-compliant resources
   - Determine if exemptions are needed
   - Plan remediation activities

3. **Monitor Compliance Over Time**:
   - Set up Azure Monitor alerts for compliance changes
   - Review compliance dashboard weekly
   - Track compliance trends

## Plan Review Checklist

Before approving any deployment, review the plan output:

### Policy Plan Review

- [ ] **New Assignments**: Review each new assignment
  - [ ] Scope is correct
  - [ ] Display name is correct
  - [ ] Parameters are correct
  - [ ] Managed identity location is correct

- [ ] **Updated Assignments**: Review changes
  - [ ] Parameter changes are intentional
  - [ ] Effect changes are intentional (Audit → Deny)
  - [ ] Scope changes are intentional

- [ ] **Deleted Assignments**: Verify deletions are intentional
  - [ ] No accidental deletions
  - [ ] Understand impact of deletion

### Roles Plan Review

- [ ] **New Role Assignments**: Review each new role
  - [ ] Principal ID matches managed identity
  - [ ] Role definition is appropriate (Contributor, Reader, etc.)
  - [ ] Scope is correct

- [ ] **Deleted Role Assignments**: Verify deletions are intentional
  - [ ] No orphaned managed identities
  - [ ] Understand impact of deletion

## Rollback Procedures

If deployment causes issues, you can rollback using git history.

### Rollback Steps

1. **Identify last working commit**:
   ```bash
   git log --oneline Definitions/
   ```

2. **Revert to previous version**:
   ```bash
   # Option 1: Revert specific commit
   git revert <commit-hash>
   
   # Option 2: Reset to previous commit (use with caution)
   git reset --hard <commit-hash>
   ```

3. **Push rollback**:
   ```bash
   git push origin main
   ```

4. **Redeploy**:
   - GitHub Actions will automatically deploy the reverted configuration
   - Or run local deployment with reverted configuration

### Emergency Rollback (Local)

If you need to immediately disable policies:

```powershell
# Disable all NIST 800-53 assignments
Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" } | 
    ForEach-Object {
        Set-AzPolicyAssignment -Id $_.ResourceId -EnforcementMode DoNotEnforce
    }
```

**Note**: This disables enforcement but keeps assignments in place. Re-enable with `-EnforcementMode Default`.

## Ongoing Maintenance

### Regular Tasks

- **Weekly**: Review compliance dashboard
- **Monthly**: Review and adjust policy effects (Audit → Deny)
- **Quarterly**: Review exemptions and remove if no longer needed
- **Annually**: Review and update NIST 800-53 parameters

### Updating Policy Parameters

1. Edit `Definitions/policyAssignments/nist-800-53-parameters.csv`
2. Change `prodEffect` or `nonprodEffect` for specific policies
3. Commit and deploy (follow deployment workflow)
4. Monitor compliance impact

### Adding Exemptions

1. Create exemption file in `Definitions/policyExemptions/`
2. Follow EPAC exemption schema
3. Commit and deploy
4. Document reason for exemption

## Troubleshooting

### Deployment Fails

**Issue**: Build-DeploymentPlans fails with "Management group not found"

**Solution**:
1. Verify management group IDs in `global-settings.jsonc`
2. Verify you have Reader permission on management groups
3. Check management group exists: `Get-AzManagementGroup -GroupId <MG-ID>`

**Issue**: Deploy-PolicyPlan fails with "Insufficient permissions"

**Solution**:
1. Verify service principal has "Resource Policy Contributor" role
2. Check role assignment scope includes target management group
3. Wait 5-10 minutes for role assignment propagation

**Issue**: Deploy-RolesPlan fails with "Principal not found"

**Solution**:
1. Verify managed identities were created (check policy assignments)
2. Wait 5-10 minutes for managed identity propagation
3. Retry deployment

### Compliance Issues

**Issue**: Policies not enforcing (resources non-compliant but not blocked)

**Solution**:
1. Check policy effect is "Deny" not "Audit"
2. Verify assignment is not in "DoNotEnforce" mode
3. Check for exemptions that may apply

**Issue**: DeployIfNotExists policies not remediating

**Solution**:
1. Verify managed identity has required permissions
2. Check role assignments for the managed identity
3. Create remediation task manually if needed

## Support

For issues or questions:

1. Review EPAC documentation: https://aka.ms/epac
2. Check GitHub Issues in this repository
3. Review Azure Policy documentation
4. Contact your Azure support team

## Appendix: Useful PowerShell Commands

```powershell
# List all NIST 800-53 assignments
Get-AzPolicyAssignment | Where-Object { $_.Properties.DisplayName -like "*NIST*" }

# Get compliance summary
Get-AzPolicyStateSummary -ManagementGroupName <MG-ID>

# List non-compliant resources
Get-AzPolicyState -ManagementGroupName <MG-ID> -Filter "ComplianceState eq 'NonCompliant'"

# Create remediation task
Start-AzPolicyRemediation -Name "nist-remediation" -PolicyAssignmentId <ASSIGNMENT-ID> -ManagementGroupName <MG-ID>

# Check remediation status
Get-AzPolicyRemediation -Name "nist-remediation" -ManagementGroupName <MG-ID>

# Export compliance report
Get-AzPolicyState -ManagementGroupName <MG-ID> | 
    Export-Csv -Path "compliance-report.csv" -NoTypeInformation
```
