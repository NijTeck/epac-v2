# Copy NIST R5 policies from built-in-policies folder to control family folders
param(
    [string]$BuiltInPath = "built-in-policies/policyDefinitions",
    [string]$OutputPath = "Definitions/policyDefinitions",
    [int]$MaxPoliciesPerFamily = 10
)

Write-Host "Loading NIST R5 policy set metadata..."

$policySetUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policySetDefinitions/Regulatory%20Compliance/NIST_SP_800-53_R5.json"
$policySet = Invoke-RestMethod -Uri $policySetUrl
$policyRefs = $policySet.properties.policyDefinitions

Write-Host "Found $($policyRefs.Count) policy references in NIST R5"
Write-Host ""

# Control family mapping
$controlFamilies = @{
    "AC" = "AC-AccessControl"
    "AT" = "AT-AwarenessAndTraining"
    "AU" = "AU-AuditAndAccountability"
    "CA" = "CA-AssessmentAuthorizationAndMonitoring"
    "CM" = "CM-ConfigurationManagement"
    "CP" = "CP-ContingencyPlanning"
    "IA" = "IA-IdentificationAndAuthentication"
    "IR" = "IR-IncidentResponse"
    "MA" = "MA-Maintenance"
    "MP" = "MP-MediaProtection"
    "PE" = "PE-PhysicalAndEnvironmentalProtection"
    "PL" = "PL-Planning"
    "PS" = "PS-PersonnelSecurity"
    "RA" = "RA-RiskAssessment"
    "SA" = "SA-SystemAndServicesAcquisition"
    "SC" = "SC-SystemAndCommunicationsProtection"
    "SI" = "SI-SystemAndInformationIntegrity"
}

# Group by control family
$policyGroups = @{}
foreach ($policyRef in $policyRefs) {
    $groupNames = $policyRef.groupNames
    
    if ($groupNames -and $groupNames.Count -gt 0) {
        foreach ($group in $groupNames) {
            if ($group -match "NIST_SP_800-53_R5_([A-Z]+)") {
                $familyCode = $Matches[1]
                $familyFolder = $controlFamilies[$familyCode]
                
                if ($familyFolder) {
                    if (-not $policyGroups.ContainsKey($familyFolder)) {
                        $policyGroups[$familyFolder] = @()
                    }
                    if ($policyGroups[$familyFolder].Count -lt $MaxPoliciesPerFamily) {
                        $policyGroups[$familyFolder] += $policyRef
                    }
                }
                break
            }
        }
    }
}

$copied = 0
$failed = 0

# Get all policy files from built-in folder
Write-Host "Scanning built-in policies folder..."
$allPolicyFiles = Get-ChildItem -Path $BuiltInPath -Recurse -Filter "*.json" -File

Write-Host "Found $($allPolicyFiles.Count) policy files"
Write-Host ""

foreach ($family in $policyGroups.Keys | Sort-Object) {
    Write-Host "Processing $family..."
    
    foreach ($policyRef in $policyGroups[$family]) {
        $policyId = $policyRef.policyDefinitionId -replace ".*/policyDefinitions/", ""
        
        # Find the policy file
        $policyFile = $allPolicyFiles | Where-Object { $_.Name -eq "$policyId.json" } | Select-Object -First 1
        
        if ($policyFile) {
            try {
                # Copy to control family folder
                $destFile = Join-Path $OutputPath $family $policyFile.Name
                Copy-Item -Path $policyFile.FullName -Destination $destFile -Force
                
                # Read to get display name
                $policyContent = Get-Content $destFile -Raw | ConvertFrom-Json
                $displayName = $policyContent.properties.displayName
                
                Write-Host "  Copied: $displayName" -ForegroundColor Green
                $copied++
            }
            catch {
                Write-Host "  Failed to copy: $policyId - $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        }
        else {
            Write-Host "  Not found: $policyId" -ForegroundColor Yellow
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Copy Summary:"
Write-Host "============="
Write-Host "Copied: $copied"
Write-Host "Failed: $failed"
Write-Host ""

# Show results
Write-Host "Policy files by family:"
foreach ($family in $controlFamilies.Values | Sort-Object) {
    $folderPath = Join-Path $OutputPath $family
    $fileCount = (Get-ChildItem $folderPath -Filter "*.json" -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) {
        Write-Host "  $family : $fileCount policies"
    }
}
