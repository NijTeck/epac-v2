# Switching from Audit to Enforcement Mode

## Understanding How Built-in Policies Work

You **DO NOT** need to copy Microsoft's built-in policies to your repository. EPAC references them by their GUID.

### What's in the CSV File

The `nist-800-53-parameters.csv` file controls built-in policies:

```csv
name,displayName,allowedEffects,defaultEffect
"3cf2ab00-13f1-4d0c-8971-2ac904541a7e","Add managed identity for Guest Config","Modify,Disabled","Modify"
```

- **name**: Policy GUID (references Microsoft's built-in policy)
- **policyType**: "BuiltIn" (no local file needed)
- **allowedEffects**: What effects this policy supports
- **defaultEffect**: What you want to use (currently "Audit" for most)

## How to Switch Policies to Enforcement

### Option 1: Change Specific Policy Categories

**Example: Enforce Guest Configuration Policies**

1. **Find the policies:**
```bash
grep -i "guest configuration" Definitions/policyAssignments/nist-800-53-parameters.csv
```

2. **Edit the CSV:**
Open `Definitions/policyAssignments/nist-800-53-parameters.csv` and find the policy rows.

Change the `defaultEffect` column:

**Before (Audit mode):**
```csv
"3cf2ab00-13f1-4d0c-8971-2ac904541a7e",...,"Modify,Disabled","Audit",...
```

**After (Enforcement mode):**
```csv
"3cf2ab00-13f1-4d0c-8971-2ac904541a7e",...,"Modify,Disabled","Modify",...
```

3. **Deploy:**
```bash
git add Definitions/policyAssignments/nist-800-53-parameters.csv
git commit -m "Enable enforcement for Guest Configuration policies"
git push
```

### Option 2: Bulk Change All Enforceable Policies

**PowerShell Script to Enable Enforcement:**

```powershell
# Load the CSV
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

# Counter for changes
$changedCount = 0

# Update each policy to use enforcement if available
foreach ($policy in $csv) {
    # Check what effects are allowed
    $allowed = $policy.allowedEffects

    # Skip if already enforcing or no enforcement available
    if ($policy.defaultEffect -in @("Deny", "DeployIfNotExists", "Modify")) {
        continue
    }

    # Change to enforcement based on what's allowed
    if ($allowed -match "Deny") {
        $policy.defaultEffect = "Deny"
        $changedCount++
        Write-Host "Changed $($policy.displayName) to Deny" -ForegroundColor Green
    }
    elseif ($allowed -match "DeployIfNotExists") {
        $policy.defaultEffect = "DeployIfNotExists"
        $changedCount++
        Write-Host "Changed $($policy.displayName) to DeployIfNotExists" -ForegroundColor Green
    }
    elseif ($allowed -match "Modify") {
        $policy.defaultEffect = "Modify"
        $changedCount++
        Write-Host "Changed $($policy.displayName) to Modify" -ForegroundColor Green
    }
}

# Save the updated CSV
$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation

Write-Host "`nTotal policies changed to enforcement: $changedCount" -ForegroundColor Cyan
```

**Save this as `Scripts/Enable-Enforcement.ps1` and run:**
```powershell
.\Scripts\Enable-Enforcement.ps1
```

### Option 3: Phased Enforcement by Control Family

**Enforce specific NIST control families:**

```powershell
# Example: Enforce all AC (Access Control) policies
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

foreach ($policy in $csv) {
    # Check if this is an Access Control policy
    if ($policy.groupNames -match "NIST_SP_800-53_R5_AC") {
        if ($policy.allowedEffects -match "Deny") {
            $policy.defaultEffect = "Deny"
            Write-Host "Enforcing: $($policy.displayName)"
        }
    }
}

$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

**Control families you can target:**
- `AC` - Access Control
- `AU` - Audit and Accountability
- `CM` - Configuration Management
- `IA` - Identification and Authentication
- `SC` - System and Communications Protection
- `SI` - System and Information Integrity

## Recommended Enforcement Strategy

### Phase 1: Low-Risk Enforcement (Week 1)
Enable enforcement for policies that auto-remediate without breaking resources:

```powershell
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

# Only enable Modify and DeployIfNotExists (these auto-fix, don't block)
foreach ($policy in $csv) {
    if ($policy.allowedEffects -match "DeployIfNotExists" -and
        $policy.defaultEffect -eq "AuditIfNotExists") {
        $policy.defaultEffect = "DeployIfNotExists"
    }
    elseif ($policy.allowedEffects -match "Modify" -and
            $policy.defaultEffect -eq "Audit") {
        $policy.defaultEffect = "Modify"
    }
}

$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

### Phase 2: Critical Controls (Week 2-3)
Enable Deny for critical security controls:

**Categories to prioritize:**
1. **Guest Configuration prerequisites** - Add managed identities
2. **Defender for Cloud** - Enable security features
3. **Diagnostic Settings** - Ensure logging
4. **Network Security** - Require NSGs, private endpoints

### Phase 3: Full Enforcement (Week 4+)
Enable all remaining enforceable policies after monitoring impact.

## Checking Current Enforcement Status

**Run the analysis script:**
```powershell
.\Scripts\Analyze-PolicyEnforcement.ps1
```

**Or check manually:**
```powershell
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

# Count by effect type
$csv | Group-Object defaultEffect |
    Select-Object Name, Count |
    Sort-Object Count -Descending
```

## Testing Before Full Deployment

### Test in Dev Environment First

1. **Change effects in CSV**
2. **Deploy to dev:**
```bash
gh workflow run "EPAC Dev Workflow" --ref working-nist800-controls
```

3. **Monitor for 24-48 hours:**
```bash
# Check for blocked resources
az policy state list \
  --management-group "11111111111111111111111111111111111111111" \
  --filter "complianceState eq 'NonCompliant' and policyDefinitionAction eq 'deny'"
```

4. **If successful, deploy to production**

## Managing Specific Policy Categories

### Guest Configuration Example

**Find all Guest Configuration policies:**
```bash
grep -i "guest configuration" Definitions/policyAssignments/nist-800-53-parameters.csv > guest-config-policies.txt
```

**Edit just those in Excel/VSCode:**
1. Open `nist-800-53-parameters.csv` in Excel or VSCode
2. Filter by category "Guest Configuration"
3. Change `defaultEffect` column from "Audit" to:
   - "Modify" for identity assignment policies
   - "AuditIfNotExists" → "DeployIfNotExists" for configuration policies
4. Save and commit

### Defender for Cloud Example

**Enable all Defender for Cloud enforcement:**
```powershell
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

$csv | Where-Object { $_.displayName -like "*Defender*" -or $_.category -eq "Security Center" } |
    ForEach-Object {
        if ($_.allowedEffects -match "DeployIfNotExists") {
            $_.defaultEffect = "DeployIfNotExists"
            Write-Host "Enforcing: $($_.displayName)"
        }
    }

$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

## Important Notes

### You Don't Need Local Policy Files

Built-in policies are referenced by GUID only. EPAC will:
1. Read the CSV to see which policies you want
2. Look up the policy definition from Azure using the GUID
3. Apply it with your specified effect and parameters

**You only need local files if:**
- Creating **custom** policies (in `Definitions/policyDefinitions/`)
- Creating **custom** policy sets (in `Definitions/policySetDefinitions/`)

### Effect Types Explained

| Effect | What It Does | When to Use |
|--------|-------------|-------------|
| **Audit** | Reports non-compliance only | Initial assessment, testing |
| **AuditIfNotExists** | Reports if resource/config missing | Same as Audit but for existence checks |
| **Deny** | **Blocks** creation of non-compliant resources | **Enforcement** - prevents violations |
| **DeployIfNotExists** | **Auto-deploys** missing resources/configs | **Enforcement** - fixes automatically |
| **Modify** | **Auto-corrects** resource settings | **Enforcement** - fixes automatically |
| **Disabled** | Policy not evaluated | Exclude policies |

### Rollback Plan

If enforcement causes issues:

```bash
# Quick rollback - revert CSV changes
git revert HEAD
git push

# Or manually change effects back to "Audit" in CSV
```

## Examples for Common Scenarios

### 1. Enforce Network Security Only

```powershell
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

$csv | Where-Object {
    $_.category -in @("Network", "Virtual Network") -or
    $_.displayName -like "*network security*" -or
    $_.displayName -like "*NSG*"
} | ForEach-Object {
    if ($_.allowedEffects -match "Deny") {
        $_.defaultEffect = "Deny"
    }
}

$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

### 2. Enforce Encryption Policies

```powershell
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

$csv | Where-Object {
    $_.displayName -like "*encrypt*" -or
    $_.displayName -like "*TLS*" -or
    $_.displayName -like "*HTTPS*"
} | ForEach-Object {
    if ($_.allowedEffects -match "Deny") {
        $_.defaultEffect = "Deny"
    }
}

$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

### 3. Enable All Auto-Remediation (Safe Start)

```powershell
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

# Only enable auto-fix policies (won't block resource creation)
$csv | Where-Object {
    $_.allowedEffects -match "DeployIfNotExists|Modify" -and
    $_.defaultEffect -notmatch "DeployIfNotExists|Modify"
} | ForEach-Object {
    if ($_.allowedEffects -match "DeployIfNotExists") {
        $_.defaultEffect = "DeployIfNotExists"
    } elseif ($_.allowedEffects -match "Modify") {
        $_.defaultEffect = "Modify"
    }
    Write-Host "Auto-remediation enabled: $($_.displayName)" -ForegroundColor Green
}

$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation
```

## Summary

✅ **Built-in policies** - No local files needed, managed via CSV
✅ **Change enforcement** - Edit `defaultEffect` column in CSV
✅ **Deploy changes** - Commit CSV and push to trigger deployment
✅ **Test first** - Always deploy to dev environment before production
✅ **Phase rollout** - Start with auto-remediation, then add Deny effects