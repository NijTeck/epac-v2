# Analyze AuditIfNotExists policies to see which can be enforced
$csv = Import-Csv "Definitions/policyAssignments/nist-800-53-parameters.csv"

# Find AuditIfNotExists policies
$auditIfNotExists = $csv | Where-Object { $_.defaultEffect -eq "AuditIfNotExists" }

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "AuditIfNotExists Policies Analysis" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check how many can be changed to DeployIfNotExists
$canEnforce = $auditIfNotExists | Where-Object { $_.allowedEffects -match "DeployIfNotExists" }
$cannotEnforce = $auditIfNotExists | Where-Object { $_.allowedEffects -notmatch "DeployIfNotExists" }

Write-Host "Total AuditIfNotExists policies: $($auditIfNotExists.Count)" -ForegroundColor Yellow
Write-Host "  Can change to DeployIfNotExists (ENFORCE): $($canEnforce.Count)" -ForegroundColor Green
Write-Host "  Cannot enforce (Audit only): $($cannotEnforce.Count)" -ForegroundColor Red
Write-Host ""

Write-Host "Why AuditIfNotExists cannot always be changed:" -ForegroundColor Yellow
Write-Host "  - Some policies check for existence of resources/settings" -ForegroundColor Gray
Write-Host "  - They can only REPORT if something is missing" -ForegroundColor Gray
Write-Host "  - They cannot AUTO-DEPLOY or BLOCK (no DeployIfNotExists option)" -ForegroundColor Gray
Write-Host ""

# Show enforceable ones by category
if ($canEnforce.Count -gt 0) {
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "Policies that CAN be enforced (change to DeployIfNotExists)" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""

    $enforceableByCategory = $canEnforce | Group-Object -Property category | Sort-Object Count -Descending

    Write-Host "Count by Category:" -ForegroundColor Cyan
    foreach ($cat in $enforceableByCategory) {
        Write-Host "  $($cat.Name): $($cat.Count) policies" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "First 20 examples:" -ForegroundColor Cyan
    $canEnforce | Select-Object -First 20 displayName, category | Format-Table -AutoSize
}

# Show non-enforceable ones
if ($cannotEnforce.Count -gt 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host "Policies that CANNOT be enforced (Audit only - no DeployIfNotExists option)" -ForegroundColor Red
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host ""

    $nonEnforceableByCategory = $cannotEnforce | Group-Object -Property category | Sort-Object Count -Descending

    Write-Host "Count by Category:" -ForegroundColor Cyan
    foreach ($cat in $nonEnforceableByCategory) {
        Write-Host "  $($cat.Name): $($cat.Count) policies" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "First 20 examples:" -ForegroundColor Cyan
    $cannotEnforce | Select-Object -First 20 displayName, category, allowedEffects | Format-Table -AutoSize
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "RECOMMENDATION:" -ForegroundColor Yellow
Write-Host ""

if ($canEnforce.Count -gt 0) {
    Write-Host "You can enable enforcement for $($canEnforce.Count) additional policies!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To enable:" -ForegroundColor Cyan
    Write-Host "  powershell -File Scripts/Enable-DeployIfNotExists.ps1" -ForegroundColor White
} else {
    Write-Host "All AuditIfNotExists policies are already at maximum enforcement." -ForegroundColor Green
}

Write-Host "=" * 80 -ForegroundColor Cyan