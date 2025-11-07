# Export full NIST R5 policies from Azure with complete content
param(
    [string]$OutputPath = "Definitions/policyDefinitions",
    [int]$MaxPoliciesPerFamily = 10
)

Write-Host "Downloading NIST R5 policy set metadata from GitHub..."

$policySetUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policySetDefinitions/Regulatory%20Compliance/NIST_SP_800-53_R5.json"
$policySet = Invoke-RestMethod -Uri $policySetUrl
$policyRefs = $policySet.properties.policyDefinitions

Write-Host "Found $($policyRefs.Count) policy references"
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

$exported = 0
$failed = 0

# Get Azure context
$context = Get-AzContext
if (-not $context) {
    Write-Host "Error: Not connected to Azure. Run Connect-AzAccount first." -ForegroundColor Red
    exit 1
}

Write-Host "Connected to: $($context.Subscription.Name)"
Write-Host ""

foreach ($family in $policyGroups.Keys | Sort-Object) {
    Write-Host "Exporting $family policies..."
    
    foreach ($policyRef in $policyGroups[$family]) {
        $policyId = $policyRef.policyDefinitionId -replace ".*/policyDefinitions/", ""
        
        try {
            # Use Azure CLI to get full policy definition
            $policyJson = az policy definition show --name $policyId 2>$null
            
            if ($LASTEXITCODE -eq 0 -and $policyJson) {
                $policy = $policyJson | ConvertFrom-Json
                
                # Create clean policy definition
                $cleanPolicy = @{
                    name = $policy.name
                    properties = @{
                        displayName = $policy.properties.displayName
                        policyType = $policy.properties.policyType
                        mode = $policy.properties.mode
                        description = $policy.properties.description
                        metadata = $policy.properties.metadata
                        parameters = $policy.properties.parameters
                        policyRule = $policy.properties.policyRule
                    }
                }
                
                # Save to file
                $outputFile = Join-Path $OutputPath $family "$policyId.json"
                $cleanPolicy | ConvertTo-Json -Depth 100 | Out-File $outputFile -Encoding UTF8
                
                Write-Host "  Exported: $($policy.properties.displayName)" -ForegroundColor Green
                $exported++
            } else {
                Write-Host "  Failed: $policyId (not found)" -ForegroundColor Red
                $failed++
            }
        }
        catch {
            Write-Host "  Failed: $policyId - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Export Summary:"
Write-Host "==============="
Write-Host "Exported: $exported"
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
