# Enable Enforcement Mode for NIST 800-53 Policies
# This script modifies the nist-800-53-parameters.csv file to change policy effects
# from Audit/AuditIfNotExists to enforcement effects (DeployIfNotExists, Modify, Append, Deny)

param(
    [string]$CsvPath = ".\Definitions\policyAssignments\nist-800-53-parameters.csv",
    [string]$BackupPath = ".\Definitions\policyAssignments\nist-800-53-parameters.csv.backup"
)

Write-Host "Reading CSV file: $CsvPath" -ForegroundColor Cyan

# Read the CSV file
$policies = Import-Csv -Path $CsvPath

Write-Host "Total policies: $($policies.Count)" -ForegroundColor Cyan

# Counter for changes
$changedCount = 0
$skippedCount = 0

# Process each policy
foreach ($policy in $policies) {
    $allowedEffects = $policy.allowedEffects
    $currentProdEffect = $policy.prodEffect

    # Skip if no allowed effects or already using enforcement
    if ([string]::IsNullOrWhiteSpace($allowedEffects)) {
        continue
    }

    # Determine the best enforcement effect to use
    $enforcementEffect = $null

    # Priority order: DeployIfNotExists > Modify > Append > Deny > AuditIfNotExists > Audit
    if ($allowedEffects -match "DeployIfNotExists") {
        $enforcementEffect = "DeployIfNotExists"
    }
    elseif ($allowedEffects -match "Modify") {
        $enforcementEffect = "Modify"
    }
    elseif ($allowedEffects -match "Append") {
        $enforcementEffect = "Append"
    }
    elseif ($allowedEffects -match "Deny") {
        $enforcementEffect = "Deny"
    }

    # If we found an enforcement effect and current is Audit/AuditIfNotExists, change it
    if ($enforcementEffect -and ($currentProdEffect -eq "Audit" -or $currentProdEffect -eq "AuditIfNotExists")) {
        Write-Host "  Changing policy: $($policy.displayName)" -ForegroundColor Yellow
        Write-Host "    From: $currentProdEffect -> To: $enforcementEffect" -ForegroundColor Yellow

        $policy.prodEffect = $enforcementEffect

        # Also update nonprodEffect to match for consistency
        if ($policy.nonprodEffect -eq "Audit" -or $policy.nonprodEffect -eq "AuditIfNotExists") {
            $policy.nonprodEffect = $enforcementEffect
        }

        $changedCount++
    }
    else {
        $skippedCount++
    }
}

Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "  Policies changed to enforcement mode: $changedCount" -ForegroundColor Green
Write-Host "  Policies kept as-is: $skippedCount" -ForegroundColor Yellow

# Export the modified CSV
Write-Host "`nExporting modified CSV to: $CsvPath" -ForegroundColor Cyan
$policies | Export-Csv -Path $CsvPath -NoTypeInformation -Force

Write-Host "`nDone! Changes saved." -ForegroundColor Green
Write-Host "Backup available at: $BackupPath" -ForegroundColor Cyan
