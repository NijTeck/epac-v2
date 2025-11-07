# Guest Configuration (Machine Configuration) Fix

## Problem

You're seeing this error:
```
This policy is unable to report compliance due to missing prerequisites to enable Azure Machine Configuration.
Fix this by assigning the prerequisite Machine Configuration initiative.
```

And remediation jobs are asking for a user-assigned managed identity instead of using the policy assignment's system-assigned managed identity.

## Root Cause

**Guest Configuration policies have a dependency chain:**

1. **First**: VMs need a **system-assigned managed identity**
2. **Second**: VMs need the **Guest Configuration extension** installed
3. **Third**: Guest Configuration policies can evaluate compliance

The NIST 800-53 policy set includes Guest Configuration policies, but it **doesn't include the prerequisite policies** to install the extension.

## Solution

Deploy the **Guest Configuration Prerequisites** policy set **before** or **alongside** the NIST 800-53 policy set.

### What Was Created

**File**: `Definitions/policyAssignments/guest-configuration-prerequisites.jsonc`

This assigns the built-in policy set:
- **Policy Set ID**: `12794019-7a00-42cf-95c2-882eed337cc8`
- **Name**: "Configure prerequisites to enable Guest Configuration policies on virtual machines"

**What it does**:
1. Adds system-assigned managed identity to VMs (if missing)
2. Deploys Guest Configuration extension to Windows VMs
3. Deploys Guest Configuration extension to Linux VMs

### Deployment Steps

#### Option 1: Deploy via EPAC (Recommended)

The prerequisite assignment file is already created. Just deploy:

```bash
# Commit the new assignment
git add Definitions/policyAssignments/guest-configuration-prerequisites.jsonc
git commit -m "feat: add Guest Configuration prerequisites assignment"
git push origin main

# Or create feature branch for testing
git checkout -b feature/guest-config-prereq
git add Definitions/policyAssignments/guest-configuration-prerequisites.jsonc
git commit -m "feat: add Guest Configuration prerequisites assignment"
git push origin feature/guest-config-prereq
```

#### Option 2: Deploy via Azure Portal (Quick Fix)

1. Navigate to **Azure Portal** > **Policy** > **Assignments**
2. Click **Assign initiative**
3. Search for: "Configure prerequisites to enable Guest Configuration"
4. Select scope: Your management group
5. Configure:
   - **Assignment name**: guest-config-prereq
   - **Managed identity**: System-assigned
   - **Managed identity location**: Same as your resources
6. Click **Review + create**

#### Option 3: Deploy via PowerShell (Quick Fix)

```powershell
# Set your management group ID
$mgId = "e1f3e196-aa55-4709-9c55-0e334c0b444f"
$scope = "/providers/Microsoft.Management/managementGroups/$mgId"

# Policy set definition ID
$policySetId = "/providers/Microsoft.Authorization/policySetDefinitions/12794019-7a00-42cf-95c2-882eed337cc8"

# Create assignment
New-AzPolicyAssignment `
    -Name "guest-config-prereq" `
    -DisplayName "Guest Configuration Prerequisites" `
    -Description "Deploys prerequisites for Guest Configuration policies" `
    -PolicySetDefinition $policySetId `
    -Scope $scope `
    -IdentityType "SystemAssigned" `
    -Location "eastus"  # Change to your region

# Get the assignment to see the managed identity
$assignment = Get-AzPolicyAssignment -Name "guest-config-prereq" -Scope $scope
Write-Host "Managed Identity Principal ID: $($assignment.Identity.PrincipalId)"

# Assign required roles to the managed identity
# The assignment needs Contributor role to deploy extensions
New-AzRoleAssignment `
    -ObjectId $assignment.Identity.PrincipalId `
    -RoleDefinitionName "Contributor" `
    -Scope $scope
```

### Create Remediation Tasks

After deploying the prerequisite assignment, create remediation tasks for existing VMs:

```powershell
# Get the assignment
$mgId = "e1f3e196-aa55-4709-9c55-0e334c0b444f"
$scope = "/providers/Microsoft.Management/managementGroups/$mgId"
$assignment = Get-AzPolicyAssignment -Name "guest-config-prereq" -Scope $scope

# Create remediation task for the entire policy set
Start-AzPolicyRemediation `
    -Name "guest-config-prereq-remediation" `
    -PolicyAssignmentId $assignment.ResourceId `
    -ManagementGroupName $mgId `
    -ResourceDiscoveryMode ReEvaluateCompliance

# Monitor remediation progress
Get-AzPolicyRemediation `
    -Name "guest-config-prereq-remediation" `
    -ManagementGroupName $mgId
```

## Why System-Assigned Managed Identity?

**System-assigned managed identity** is automatically created by Azure Policy when:
1. The policy assignment has `"identity": { "type": "SystemAssigned" }`
2. The policy effect is `DeployIfNotExists` or `Modify`

**Benefits**:
- Automatically created and managed by Azure
- Lifecycle tied to the policy assignment
- No need to create separate user-assigned identities
- EPAC automatically assigns required roles

**User-assigned managed identity** is only needed if:
- You want to share identity across multiple assignments
- You need specific RBAC configurations
- You're using custom policies with specific identity requirements

## Verification

After deploying the prerequisites:

### Check Assignment

```powershell
# Verify assignment exists
Get-AzPolicyAssignment -Name "guest-config-prereq"

# Check managed identity
$assignment = Get-AzPolicyAssignment -Name "guest-config-prereq"
$assignment.Identity
```

### Check Compliance

```powershell
# Wait 30 minutes for policy evaluation
Start-Sleep -Seconds 1800

# Check compliance
Get-AzPolicyState -ManagementGroupName $mgId -Filter "PolicyAssignmentName eq 'guest-config-prereq'"
```

### Check VMs

```powershell
# Check if VMs have system-assigned identity
Get-AzVM | Select-Object Name, @{N='IdentityType';E={$_.Identity.Type}}

# Check if Guest Configuration extension is installed
Get-AzVM | ForEach-Object {
    $vm = $_
    $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
    $gcExtension = $extensions | Where-Object { $_.Publisher -eq "Microsoft.GuestConfiguration" }
    
    [PSCustomObject]@{
        VMName = $vm.Name
        HasGuestConfigExtension = ($gcExtension -ne $null)
        ExtensionStatus = $gcExtension.ProvisioningState
    }
}
```

## Timeline

1. **Deploy prerequisite assignment**: 5 minutes
2. **Policy evaluation**: 30 minutes
3. **Remediation tasks**: 10-30 minutes per VM
4. **Guest Configuration ready**: After remediation completes
5. **NIST 800-53 Guest Config policies work**: Immediately after

## Troubleshooting

### Issue: Remediation task fails

**Check managed identity permissions**:
```powershell
$assignment = Get-AzPolicyAssignment -Name "guest-config-prereq"
Get-AzRoleAssignment -ObjectId $assignment.Identity.PrincipalId
```

**Solution**: Assign Contributor role:
```powershell
New-AzRoleAssignment `
    -ObjectId $assignment.Identity.PrincipalId `
    -RoleDefinitionName "Contributor" `
    -Scope $scope
```

### Issue: VMs still non-compliant after remediation

**Check extension installation**:
```powershell
Get-AzVMExtension -ResourceGroupName "<rg-name>" -VMName "<vm-name>" | 
    Where-Object { $_.Publisher -eq "Microsoft.GuestConfiguration" }
```

**Solution**: Manually install extension:
```powershell
# For Windows VMs
Set-AzVMExtension `
    -ResourceGroupName "<rg-name>" `
    -VMName "<vm-name>" `
    -Name "AzurePolicyforWindows" `
    -Publisher "Microsoft.GuestConfiguration" `
    -Type "ConfigurationforWindows" `
    -TypeHandlerVersion "1.0"

# For Linux VMs
Set-AzVMExtension `
    -ResourceGroupName "<rg-name>" `
    -VMName "<vm-name>" `
    -Name "AzurePolicyforLinux" `
    -Publisher "Microsoft.GuestConfiguration" `
    -Type "ConfigurationforLinux" `
    -TypeHandlerVersion "1.0"
```

### Issue: "Missing managed identity" error persists

**Check if VM has system-assigned identity**:
```powershell
$vm = Get-AzVM -ResourceGroupName "<rg-name>" -Name "<vm-name>"
$vm.Identity
```

**Solution**: Enable system-assigned identity:
```powershell
Update-AzVM -ResourceGroupName "<rg-name>" -VM $vm -IdentityType SystemAssigned
```

## Policy Dependencies

**Guest Configuration policies in NIST 800-53 that require prerequisites**:

1. Windows machines should meet requirements for 'Security Options - Accounts'
2. Windows machines should meet requirements for 'Security Options - Audit'
3. Windows machines should meet requirements for 'Security Options - Network Access'
4. Windows machines should meet requirements for 'System Audit Policies'
5. Linux machines should have the Azure Monitor Agent installed
6. Windows machines should have the Azure Monitor Agent installed
7. And many more...

**All of these require**:
- System-assigned managed identity on VM
- Guest Configuration extension installed

## Best Practices

1. **Deploy prerequisites first**: Always deploy Guest Configuration prerequisites before NIST 800-53
2. **Use system-assigned identity**: Let Azure Policy manage the identity lifecycle
3. **Create remediation tasks**: For existing VMs, create remediation tasks after assignment
4. **Monitor remediation**: Check remediation task status regularly
5. **Wait for evaluation**: Allow 30-60 minutes for initial policy evaluation

## Summary

✅ **Created**: `guest-configuration-prerequisites.jsonc` assignment file
✅ **Configured**: System-assigned managed identity
✅ **Ready to deploy**: Via EPAC, Portal, or PowerShell

**Next steps**:
1. Deploy the prerequisite assignment
2. Wait 30 minutes for evaluation
3. Create remediation tasks for existing VMs
4. Verify Guest Configuration extension is installed
5. NIST 800-53 Guest Configuration policies will now work

This fixes the "missing prerequisites" error and ensures remediation uses the policy assignment's managed identity! 🎯
