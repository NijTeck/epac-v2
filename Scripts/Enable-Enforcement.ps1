# Enable Enforcement Mode for NIST 800-53 Policies
# This script changes policies from Audit to Enforcement (Deny/DeployIfNotExists/Modify)

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("All", "AutoRemediate", "Deny", "Category", "ByControl")]
    [string]$Mode = "AutoRemediate",

    [Parameter()]
    [string]$Category = "",

    [Parameter()]
    [string]$ControlFamily = "",

    [Parameter()]
    [switch]$WhatIf
)

$csvPath = "Definitions/policyAssignments/nist-800-53-parameters.csv"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NIST 800-53 Enforcement Enablement Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load CSV
Write-Host "Loading policy configuration from CSV..." -ForegroundColor Yellow
$policies = Import-Csv $csvPath

$totalPolicies = $policies.Count
Write-Host "Total policies: $totalPolicies" -ForegroundColor White
Write-Host ""

# Track changes
$changes = @()

switch ($Mode) {
    "AutoRemediate" {
        Write-Host "MODE: Auto-Remediation Only (Safe Start)" -ForegroundColor Green
        Write-Host "This will enable DeployIfNotExists and Modify effects only." -ForegroundColor Gray
        Write-Host "These policies auto-fix issues without blocking resource creation." -ForegroundColor Gray
        Write-Host ""

        foreach ($policy in $policies) {
            $originalEffect = $policy.defaultEffect

            # Change AuditIfNotExists to DeployIfNotExists
            if ($policy.defaultEffect -eq "AuditIfNotExists" -and
                $policy.allowedEffects -match "DeployIfNotExists") {
                $policy.defaultEffect = "DeployIfNotExists"
                $changes += [PSCustomObject]@{
                    Policy = $policy.displayName
                    From = $originalEffect
                    To = "DeployIfNotExists"
                    Category = $policy.category
                }
            }
            # Change Audit to Modify
            elseif ($policy.defaultEffect -eq "Audit" -and
                    $policy.allowedEffects -match "Modify") {
                $policy.defaultEffect = "Modify"
                $changes += [PSCustomObject]@{
                    Policy = $policy.displayName
                    From = $originalEffect
                    To = "Modify"
                    Category = $policy.category
                }
            }
        }
    }

    "Deny" {
        Write-Host "MODE: Enable Deny Effect (Full Enforcement)" -ForegroundColor Red
        Write-Host "WARNING: This will BLOCK creation of non-compliant resources!" -ForegroundColor Yellow
        Write-Host ""

        foreach ($policy in $policies) {
            if ($policy.defaultEffect -eq "Audit" -and
                $policy.allowedEffects -match "Deny") {
                $originalEffect = $policy.defaultEffect
                $policy.defaultEffect = "Deny"
                $changes += [PSCustomObject]@{
                    Policy = $policy.displayName
                    From = $originalEffect
                    To = "Deny"
                    Category = $policy.category
                }
            }
        }
    }

    "All" {
        Write-Host "MODE: Enable All Enforcement (Maximum Compliance)" -ForegroundColor Red
        Write-Host "WARNING: This is aggressive - test in dev first!" -ForegroundColor Yellow
        Write-Host ""

        foreach ($policy in $policies) {
            $originalEffect = $policy.defaultEffect

            # Skip if already enforcing
            if ($originalEffect -in @("Deny", "DeployIfNotExists", "Modify")) {
                continue
            }

            # Prefer Deny > DeployIfNotExists > Modify
            if ($policy.allowedEffects -match "Deny") {
                $policy.defaultEffect = "Deny"
                $newEffect = "Deny"
            }
            elseif ($policy.allowedEffects -match "DeployIfNotExists") {
                $policy.defaultEffect = "DeployIfNotExists"
                $newEffect = "DeployIfNotExists"
            }
            elseif ($policy.allowedEffects -match "Modify") {
                $policy.defaultEffect = "Modify"
                $newEffect = "Modify"
            }
            else {
                continue
            }

            $changes += [PSCustomObject]@{
                Policy = $policy.displayName
                From = $originalEffect
                To = $newEffect
                Category = $policy.category
            }
        }
    }

    "Category" {
        if ([string]::IsNullOrEmpty($Category)) {
            Write-Host "ERROR: -Category parameter required for this mode" -ForegroundColor Red
            exit 1
        }

        Write-Host "MODE: Enable Enforcement for Category: $Category" -ForegroundColor Green
        Write-Host ""

        foreach ($policy in $policies) {
            if ($policy.category -ne $Category) {
                continue
            }

            $originalEffect = $policy.defaultEffect

            # Enable strongest enforcement available
            if ($policy.allowedEffects -match "Deny") {
                $policy.defaultEffect = "Deny"
                $newEffect = "Deny"
            }
            elseif ($policy.allowedEffects -match "DeployIfNotExists") {
                $policy.defaultEffect = "DeployIfNotExists"
                $newEffect = "DeployIfNotExists"
            }
            elseif ($policy.allowedEffects -match "Modify") {
                $policy.defaultEffect = "Modify"
                $newEffect = "Modify"
            }
            else {
                continue
            }

            $changes += [PSCustomObject]@{
                Policy = $policy.displayName
                From = $originalEffect
                To = $newEffect
                Category = $policy.category
            }
        }
    }

    "ByControl" {
        if ([string]::IsNullOrEmpty($ControlFamily)) {
            Write-Host "ERROR: -ControlFamily parameter required for this mode" -ForegroundColor Red
            Write-Host "Examples: AC, AU, CM, IA, SC, SI" -ForegroundColor Yellow
            exit 1
        }

        Write-Host "MODE: Enable Enforcement for Control Family: $ControlFamily" -ForegroundColor Green
        Write-Host ""

        foreach ($policy in $policies) {
            if ($policy.groupNames -notmatch "NIST_SP_800-53_R5_$ControlFamily") {
                continue
            }

            $originalEffect = $policy.defaultEffect

            # Enable strongest enforcement available
            if ($policy.allowedEffects -match "Deny") {
                $policy.defaultEffect = "Deny"
                $newEffect = "Deny"
            }
            elseif ($policy.allowedEffects -match "DeployIfNotExists") {
                $policy.defaultEffect = "DeployIfNotExists"
                $newEffect = "DeployIfNotExists"
            }
            elseif ($policy.allowedEffects -match "Modify") {
                $policy.defaultEffect = "Modify"
                $newEffect = "Modify"
            }
            else {
                continue
            }

            $changes += [PSCustomObject]@{
                Policy = $policy.displayName
                From = $originalEffect
                To = $newEffect
                Category = $policy.category
            }
        }
    }
}

# Display changes
if ($changes.Count -eq 0) {
    Write-Host "No changes needed - all policies already configured correctly." -ForegroundColor Green
    exit 0
}

Write-Host "CHANGES TO BE MADE:" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
$changes | Format-Table -AutoSize

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total changes: $($changes.Count)" -ForegroundColor White

# Group by new effect
$effectSummary = $changes | Group-Object -Property To | Select-Object Name, Count
foreach ($effect in $effectSummary) {
    Write-Host "  - $($effect.Name): $($effect.Count) policies" -ForegroundColor White
}

# Group by category
Write-Host ""
Write-Host "Changes by Category:" -ForegroundColor Cyan
$categorySummary = $changes | Group-Object -Property Category | Sort-Object Count -Descending | Select-Object -First 10
foreach ($cat in $categorySummary) {
    Write-Host "  - $($cat.Name): $($cat.Count) policies" -ForegroundColor White
}

Write-Host ""

# Save or preview
if ($WhatIf) {
    Write-Host "WHAT-IF MODE: No changes saved to CSV" -ForegroundColor Yellow
    Write-Host "Remove -WhatIf to apply changes" -ForegroundColor Gray
}
else {
    # Confirm if using Deny mode
    if ($Mode -in @("Deny", "All")) {
        Write-Host "WARNING: This will enable blocking policies!" -ForegroundColor Red
        $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "Cancelled by user" -ForegroundColor Yellow
            exit 0
        }
    }

    # Save changes
    Write-Host "Saving changes to CSV..." -ForegroundColor Yellow
    $policies | Export-Csv $csvPath -NoTypeInformation
    Write-Host "✅ Changes saved successfully!" -ForegroundColor Green

    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review changes: git diff $csvPath" -ForegroundColor White
    Write-Host "2. Commit changes: git add $csvPath && git commit -m 'Enable enforcement mode'" -ForegroundColor White
    Write-Host "3. Deploy to dev first: gh workflow run 'EPAC Dev Workflow'" -ForegroundColor White
    Write-Host "4. Monitor for 24-48 hours" -ForegroundColor White
    Write-Host "5. Deploy to production if successful" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan