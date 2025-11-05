# Analyze NIST 800-53 Policy Enforcement Status
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "NIST 800-53 POLICY ENFORCEMENT ANALYSIS" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Load the CSV file
$policies = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

# Get total policy count
$totalPolicies = $policies.Count
Write-Host "Total NIST 800-53 Policies: $totalPolicies" -ForegroundColor Yellow
Write-Host ""

# Group by current effect
Write-Host "CURRENT POLICY EFFECTS DISTRIBUTION:" -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray
$effectGroups = $policies | Group-Object -Property defaultEffect | Sort-Object Count -Descending
foreach ($group in $effectGroups) {
    $percentage = [math]::Round(($group.Count / $totalPolicies) * 100, 1)
    Write-Host "$($group.Name.PadRight(20)) : $($group.Count.ToString().PadLeft(4)) policies ($percentage%)" -ForegroundColor White
}
Write-Host ""

# Analyze enforcement capabilities
Write-Host "ENFORCEMENT CAPABILITIES ANALYSIS:" -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

# Count policies that CAN enforce (have Deny, DeployIfNotExists, or Modify in allowedEffects)
$enforceable = $policies | Where-Object {
    $_.allowedEffects -match "Deny|DeployIfNotExists|Modify"
}
$enforceableCount = $enforceable.Count
$enforceablePercentage = [math]::Round(($enforceableCount / $totalPolicies) * 100, 1)

Write-Host "Policies with enforcement capability: $enforceableCount ($enforceablePercentage%)" -ForegroundColor Yellow
Write-Host "(Can use Deny, DeployIfNotExists, or Modify)" -ForegroundColor Gray
Write-Host ""

# Count policies currently in enforcement mode
$enforcing = $policies | Where-Object {
    $_.defaultEffect -in @("Deny", "DeployIfNotExists", "Modify")
}
$enforcingCount = $enforcing.Count
$enforcingPercentage = [math]::Round(($enforcingCount / $totalPolicies) * 100, 1)

Write-Host "Policies CURRENTLY ENFORCING: $enforcingCount ($enforcingPercentage%)" -ForegroundColor Cyan
Write-Host ""

# Analyze by enforcement type
Write-Host "ENFORCEMENT TYPES AVAILABLE:" -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

$denyCapable = ($policies | Where-Object { $_.allowedEffects -match "Deny" }).Count
$deployCapable = ($policies | Where-Object { $_.allowedEffects -match "DeployIfNotExists" }).Count
$modifyCapable = ($policies | Where-Object { $_.allowedEffects -match "Modify" }).Count

Write-Host "Can use Deny effect         : $denyCapable policies" -ForegroundColor White
Write-Host "Can use DeployIfNotExists   : $deployCapable policies" -ForegroundColor White
Write-Host "Can use Modify effect       : $modifyCapable policies" -ForegroundColor White
Write-Host ""

# Analyze audit vs enforcement
Write-Host "COMPLIANCE MODE ANALYSIS:" -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

$auditMode = $policies | Where-Object {
    $_.defaultEffect -in @("Audit", "AuditIfNotExists")
}
$auditCount = $auditMode.Count
$auditPercentage = [math]::Round(($auditCount / $totalPolicies) * 100, 1)

Write-Host "Audit/Report Mode    : $auditCount policies ($auditPercentage%)" -ForegroundColor Yellow
Write-Host "Enforcement Mode     : $enforcingCount policies ($enforcingPercentage%)" -ForegroundColor Green
Write-Host "Disabled             : $(($policies | Where-Object { $_.defaultEffect -eq 'Disabled' }).Count) policies" -ForegroundColor Gray
Write-Host ""

# Technical controls analysis
Write-Host "TECHNICAL CONTROLS COVERAGE:" -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

# Group by NIST control categories
$controlGroups = @{}
foreach ($policy in $policies) {
    if ($policy.groupNames) {
        $groups = $policy.groupNames -split ","
        foreach ($group in $groups) {
            $group = $group.Trim()
            if ($group -match "NIST_SP_800-53_R5_(.+?)(\(|$)") {
                $controlCategory = $matches[1]
                if (-not $controlGroups.ContainsKey($controlCategory)) {
                    $controlGroups[$controlCategory] = @{
                        Total = 0
                        Enforcing = 0
                        Auditing = 0
                    }
                }
                $controlGroups[$controlCategory].Total++
                if ($policy.defaultEffect -in @("Deny", "DeployIfNotExists", "Modify")) {
                    $controlGroups[$controlCategory].Enforcing++
                } elseif ($policy.defaultEffect -in @("Audit", "AuditIfNotExists")) {
                    $controlGroups[$controlCategory].Auditing++
                }
            }
        }
    }
}

# Display top control categories
$sortedControls = $controlGroups.GetEnumerator() | Sort-Object { $_.Value.Total } -Descending | Select-Object -First 10
Write-Host "Top 10 Control Categories:" -ForegroundColor Yellow
foreach ($control in $sortedControls) {
    $enforcePct = if ($control.Value.Total -gt 0) {
        [math]::Round(($control.Value.Enforcing / $control.Value.Total) * 100, 0)
    } else { 0 }

    $status = if ($enforcePct -gt 50) { "ENFORCING" }
              elseif ($enforcePct -gt 0) { "PARTIAL" }
              else { "AUDIT ONLY" }

    $color = if ($status -eq "ENFORCING") { "Green" }
             elseif ($status -eq "PARTIAL") { "Yellow" }
             else { "Red" }

    Write-Host "$($control.Key.PadRight(8)): Total=$($control.Value.Total.ToString().PadLeft(3)), Enforcing=$($control.Value.Enforcing.ToString().PadLeft(3)) ($enforcePct%) - $status" -ForegroundColor $color
}
Write-Host ""

# Summary and recommendations
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

if ($enforcingPercentage -lt 5) {
    Write-Host "⚠ CURRENT STATE: PRIMARILY AUDIT/REPORT MODE" -ForegroundColor Red
    Write-Host "  - Only $enforcingCount out of $totalPolicies policies are enforcing" -ForegroundColor Yellow
    Write-Host "  - Most policies ($auditPercentage%) are in audit mode" -ForegroundColor Yellow
    Write-Host "  - Technical controls are NOT actively enforced" -ForegroundColor Yellow
} elseif ($enforcingPercentage -lt 30) {
    Write-Host "⚠ CURRENT STATE: LIMITED ENFORCEMENT" -ForegroundColor Yellow
    Write-Host "  - $enforcingCount policies are enforcing ($enforcingPercentage%)" -ForegroundColor Yellow
    Write-Host "  - Majority still in audit mode ($auditPercentage%)" -ForegroundColor Yellow
    Write-Host "  - Some technical controls are enforced" -ForegroundColor Green
} else {
    Write-Host "✅ CURRENT STATE: ACTIVE ENFORCEMENT" -ForegroundColor Green
    Write-Host "  - $enforcingCount policies are enforcing ($enforcingPercentage%)" -ForegroundColor Green
    Write-Host "  - Technical controls are actively enforced" -ForegroundColor Green
}

Write-Host ""
Write-Host "POTENTIAL FOR ENFORCEMENT:" -ForegroundColor Green
Write-Host "  - $enforceableCount policies ($enforceablePercentage%) CAN be set to enforce" -ForegroundColor White
Write-Host "  - Would need to change from Audit to Deny/DeployIfNotExists/Modify" -ForegroundColor White
Write-Host ""

Write-Host "TO ENABLE FULL ENFORCEMENT MODE:" -ForegroundColor Cyan
Write-Host "1. Run: .\Scripts\Enable-FullEnforcement.ps1" -ForegroundColor White
Write-Host "2. Review and approve changes" -ForegroundColor White
Write-Host "3. Deploy via GitHub Actions" -ForegroundColor White
Write-Host "4. Monitor for compliance issues" -ForegroundColor White
Write-Host ""