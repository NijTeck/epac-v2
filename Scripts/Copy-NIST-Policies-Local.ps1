# Copy ALL NIST R5 policies from local built-in-policies folder
param(
    [string]$PolicySetFile = "built-in-policies/policySetDefinitions/Regulatory Compliance/NIST_SP_800-53_R5.json",
    [string]$BuiltInPath = "built-in-policies/policyDefinitions",
    [string]$OutputPath = "Definitions/policyDefinitions"
)

Write-Host "Loading NIST R5 policy set from local file..."

$policySet = Get-Content $PolicySetFile -Raw | ConvertFrom-Json
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

# Build index of all policy files by their ID
Write-Host "Building index of policy files..."
$allPolicyFiles = Get-ChildItem -Path $BuiltInPath -Recurse -Filter "*.json" -File
$policyIndex = @{}

$indexed = 0
foreach ($file in $allPolicyFiles) {
    try {
        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $policyIndex[$content.name] = $file.FullName
        $indexed++
        
        if ($indexed % 500 -eq 0) {
            Write-Host "  Indexed $indexed policies..."
        }
    }
    catch {
        continue
    }
}

Write-Host "Indexed $indexed policy files"
Write-Host ""

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
                    $policyGroups[$familyFolder] += $policyRef
                }
                break
            }
        }
    }
}

$copied = 0
$failed = 0

foreach ($family in $policyGroups.Keys | Sort-Object) {
    Write-Host "Processing $family ($($policyGroups[$family].Count) policies)..."
    
    foreach ($policyRef in $policyGroups[$family]) {
        $policyId = $policyRef.policyDefinitionId -replace ".*/policyDefinitions/", ""
        
        if ($policyIndex.ContainsKey($policyId)) {
            try {
                $sourceFile = $policyIndex[$policyId]
                $fileName = [System.IO.Path]::GetFileName($sourceFile)
                $destFile = Join-Path $OutputPath $family $fileName
                
                Copy-Item -LiteralPath $sourceFile -Destination $destFile -Force
                
                # Get display name
                $content = Get-Content $destFile -Raw | ConvertFrom-Json
                $displayName = $content.properties.displayName
                
                Write-Host "  Copied: $displayName" -ForegroundColor Green
                $copied++
            }
            catch {
                Write-Host "  Failed to copy: $policyId - $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        }
        else {
            Write-Host "  Not found in index: $policyId" -ForegroundColor Yellow
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Copy Summary:"
Write-Host "============="
Write-Host "Copied: $copied"
Write-Host "Not Found: $failed"
Write-Host ""

# Show results
Write-Host "Policy files by family:"
$totalPolicies = 0
foreach ($family in $controlFamilies.Values | Sort-Object) {
    $folderPath = Join-Path $OutputPath $family
    $fileCount = (Get-ChildItem $folderPath -Filter "*.json" -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) {
        Write-Host "  $family : $fileCount policies"
        $totalPolicies += $fileCount
    }
}
Write-Host ""
Write-Host "Total: $totalPolicies policies"
