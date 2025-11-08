# Apply enforcement mode immediately - no confirmation needed
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"
$changedCount = 0
$changes = @()

foreach ($policy in $csv) {
    $originalEffect = $policy.defaultEffect

    # Skip if already enforcing
    if ($originalEffect -in @("Deny", "DeployIfNotExists", "Modify")) {
        continue
    }

    # Enable strongest enforcement available
    $newEffect = $null
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

    if ($newEffect) {
        $changedCount++
        $changes += [PSCustomObject]@{
            Policy = $policy.displayName
            Category = $policy.category
            From = $originalEffect
            To = $newEffect
        }
    }
}

# Save changes
$csv | Export-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv" -NoTypeInformation

Write-Host "=" * 80 -ForegroundColor Green
Write-Host "ENFORCEMENT MODE ENABLED" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host ""
Write-Host "Total policies changed: $changedCount" -ForegroundColor Cyan
Write-Host ""

# Show summary by effect type
Write-Host "Changes by Effect Type:" -ForegroundColor Yellow
$changes | Group-Object -Property To | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) policies" -ForegroundColor White
}

Write-Host ""
Write-Host "Changes by Category (Top 10):" -ForegroundColor Yellow
$changes | Group-Object -Property Category | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) policies" -ForegroundColor White
}

Write-Host ""
Write-Host "Current Policy Distribution:" -ForegroundColor Cyan
$csv | Group-Object -Property defaultEffect | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) policies" -ForegroundColor White
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Review changes: git diff Definitions/policyAssignments/nist-800-53-parameters.csv" -ForegroundColor White
Write-Host "2. Commit: git add Definitions/policyAssignments/nist-800-53-parameters.csv" -ForegroundColor White
Write-Host "3. Commit: git commit -m 'Enable enforcement mode for all enforceable policies'" -ForegroundColor White
Write-Host "4. Push: git push" -ForegroundColor White
Write-Host "=" * 80 -ForegroundColor Green