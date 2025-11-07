# How to Override Policy Effects in EPAC

You have **full control** over policy effects even for built-in policies. You don't need local copies - just override the effects in your assignment file.

## Quick Start

### Option 1: Override ALL Policies (Global Effect)

Add a single `effect` parameter to change all policies at once:

```jsonc
{
  "parameters": {
    "effect": "Audit"  // Changes ALL policies to Audit mode
  }
}
```

### Option 2: Override Specific Policies

Override individual policies by their parameter name:

```jsonc
{
  "parameters": {
    // Storage policies
    "StorageAccountsShouldRestrictNetworkAccess_effect": "Deny",
    "StorageAccountsShouldUsePrivateLink_effect": "Audit",
    
    // SQL policies  
    "SQLServersShouldHaveAuditingEnabled_effect": "DeployIfNotExists",
    "SQLDatabasesShouldHaveTransparentDataEncryption_effect": "Deny",
    
    // VM policies
    "VirtualMachinesShouldEncryptTempDisks_effect": "Audit",
    "WindowsMachinesShouldMeetRequirements_effect": "AuditIfNotExists"
  }
}
```

## Available Effects

Most policies support these effects:

- **Audit** - Log non-compliant resources (no blocking)
- **Deny** - Block non-compliant resource creation/updates
- **Disabled** - Turn off the policy
- **AuditIfNotExists** - Audit if a related resource doesn't exist
- **DeployIfNotExists** - Auto-deploy missing configurations (requires managed identity)

## Finding Policy IDs and Parameters

### Method 1: Use the Helper Script

```powershell
# Search for specific policies
.\Scripts\Get-PolicyEffectParameters.ps1 -SearchTerm "Storage"

# Filter by control family
.\Scripts\Get-PolicyEffectParameters.ps1 -ControlFamily "AC"

# Show all policies with configurable effects
.\Scripts\Get-PolicyEffectParameters.ps1 -ShowAll
```

### Method 2: Azure Portal

1. Go to **Azure Portal > Policy > Definitions**
2. Search for the policy by name
3. Click on the policy
4. View the **JSON** tab
5. Look for `"parameters"` section
6. Find the `"effect"` parameter and its `"allowedValues"`

### Method 3: Check the NIST R5 Policy Set

The policy set at `built-in-policies/policySetDefinitions/Regulatory Compliance/NIST_SP_800-53_R5.json` lists all 698 policies with their IDs.

## Example: Audit Mode for Testing

To test your policies without blocking resources, set everything to Audit:

```jsonc
{
  "parameters": {
    "effect": "Audit",  // Global audit mode
    
    // Keep critical security policies as Deny
    "PublicNetworkAccessShouldBeDisabled_effect": "Deny",
    "StorageAccountsShouldPreventSharedKeyAccess_effect": "Deny"
  }
}
```

## Example: Enforcement Mode for Production

```jsonc
{
  "parameters": {
    "effect": "Deny",  // Block non-compliant resources
    
    // Exceptions for policies that need auto-remediation
    "DefenderForCloudShouldBeEnabled_effect": "DeployIfNotExists",
    "DiagnosticSettingsShouldBeEnabled_effect": "DeployIfNotExists",
    
    // Exceptions for policies still in testing
    "LegacyAuthenticationShouldBeBlocked_effect": "Audit"
  }
}
```

## Common Patterns

### Start with Audit, Move to Deny

1. **Phase 1 - Discovery**: Set all to `Audit` to identify non-compliant resources
2. **Phase 2 - Remediation**: Fix non-compliant resources
3. **Phase 3 - Enforcement**: Change critical policies to `Deny`
4. **Phase 4 - Full Enforcement**: Set global effect to `Deny`

### Control Family-Based Enforcement

You can't filter by control family in the assignment, but you can:

1. Use the helper script to list policies by family
2. Copy the policy IDs for that family
3. Override them in your assignment

```powershell
# Get all AC (Access Control) policies
.\Scripts\Get-PolicyEffectParameters.ps1 -ControlFamily "AC" > ac-policies.txt
```

## Current Assignment Configuration

Your current assignment (`comprehensive-nist-800-53-assignment.jsonc`) includes:

- **698 built-in NIST R5 policies** (referenced by ID)
- **5 custom enforcement policies** (stored locally)
- **Default effects** as defined by Microsoft
- **Custom parameters** for Defender for Cloud and security contacts

To override effects, simply add parameters to the `parameters` section.

## Testing Your Changes

After modifying the assignment:

```powershell
# 1. Build the EPAC plan
.\Scripts\Deploy\Build-DeploymentPlans.ps1 -PacEnvironmentSelector epac-dev

# 2. Review the plan
# Check Output/Plans/epac-dev/*.json

# 3. Deploy
.\Scripts\Deploy\Deploy-PolicyPlan.ps1 -PacEnvironmentSelector epac-dev
```

## Need Help?

Run the helper script to explore available policies:

```powershell
.\Scripts\Get-PolicyEffectParameters.ps1 -SearchTerm "keyword"
```

Or check the Azure Policy documentation:
https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects
