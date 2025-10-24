# Update NIST 800-53 parameters CSV for auto-remediation
# This script changes policy effects from Audit to DeployIfNotExists/Modify for automatic remediation

$csvPath = Join-Path $PSScriptRoot "..\Definitions\policyAssignments\nist-800-53-parameters.csv"

Write-Host "Updating NIST 800-53 parameters for auto-remediation..." -ForegroundColor Green

# Read the current CSV
$csv = Import-Csv $csvPath

# Define which controls should use which remediation effect
$remediationEffects = @{
    # Audit and Accountability - Use DeployIfNotExists for diagnostic settings
    "Audit Record Generation" = "DeployIfNotExists"
    "System-wide and Time-correlated Audit Trail" = "DeployIfNotExists"
    "Central Review and Analysis" = "DeployIfNotExists"
    "Integrated Analysis of Audit Records" = "DeployIfNotExists"

    # Incident Response - Use DeployIfNotExists for monitoring
    "Incident Handling" = "DeployIfNotExists"
    "Incident Monitoring" = "DeployIfNotExists"

    # System and Information Integrity - Use DeployIfNotExists/Modify
    "Vulnerability Monitoring and Scanning" = "DeployIfNotExists"
    "Flaw Remediation" = "Modify"
    "Malicious Code Protection" = "DeployIfNotExists"

    # Access Control - Use Modify for configuration changes
    "Remote Access" = "Modify"
    "Information Flow Enforcement" = "Modify"
    "Separation of Duties" = "Audit"  # Keep as Audit - requires manual review
    "Least Privilege" = "Modify"
    "Unsuccessful Logon Attempts" = "Modify"

    # Configuration Management - Use Modify for settings
    "Configuration Settings" = "Modify"
    "Least Functionality" = "Modify"

    # Identification and Authentication - Use Modify
    "Password-based Authentication" = "Modify"
    "Authenticator Management" = "Modify"

    # System and Communications Protection - Use DeployIfNotExists
    "Boundary Protection" = "DeployIfNotExists"
    "Access Points" = "Modify"
    "External System Connections" = "Modify"
    "Cryptographic Protection" = "DeployIfNotExists"
}

# Update the CSV with appropriate effects
$updatedCsv = @()
foreach ($row in $csv) {
    $controlName = $row.ControlName

    # Check if this control should be auto-remediated
    if ($remediationEffects.ContainsKey($controlName)) {
        $row.defaultEffect = $remediationEffects[$controlName]
        Write-Host "  - Updated '$controlName' to $($remediationEffects[$controlName])" -ForegroundColor Yellow
    } else {
        # Keep as Audit for controls not in our remediation list
        if ([string]::IsNullOrEmpty($row.defaultEffect)) {
            $row.defaultEffect = "Audit"
        }
    }

    # Ensure defaultParameters column exists
    if (-not $row.PSObject.Properties.Name -contains 'defaultParameters') {
        $row | Add-Member -NotePropertyName 'defaultParameters' -NotePropertyValue ''
    }

    $updatedCsv += $row
}

# Export the updated CSV
$updatedCsv | Export-Csv $csvPath -NoTypeInformation

Write-Host "`nCSV updated successfully!" -ForegroundColor Green
Write-Host "Total controls updated for auto-remediation: $($remediationEffects.Count)" -ForegroundColor Cyan

# Display summary
$summary = $updatedCsv | Group-Object -Property defaultEffect | Select-Object Name, Count
Write-Host "`nEffect Summary:" -ForegroundColor Green
$summary | ForEach-Object {
    Write-Host "  - $($_.Name): $($_.Count) controls" -ForegroundColor White
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review the changes in the CSV file" -ForegroundColor White
Write-Host "2. Commit and push to trigger deployment" -ForegroundColor White
Write-Host "3. Run remediation tasks after deployment" -ForegroundColor White