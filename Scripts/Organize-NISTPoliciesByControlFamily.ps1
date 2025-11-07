# Script to organize NIST 800-53 policies by control family
# Extracts policies from the NIST initiative and organizes them by control family

param(
    [string]$InitiativeJsonPath = "nist-r5-initiative-full.json",
    [string]$OutputPath = "Definitions/policyDefinitions"
)

Write-Host "Loading NIST initiative from $InitiativeJsonPath..."
$initiative = Get-Content $InitiativeJsonPath | ConvertFrom-Json

$policies = $initiative.PolicyDefinition
Write-Host "Found $($policies.Count) policies in initiative"

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
    "PM" = "PM-ProgramManagement"
    "PS" = "PS-PersonnelSecurity"
    "PT" = "PT-PIIProcessingAndTransparency"
    "RA" = "RA-RiskAssessment"
    "SA" = "SA-SystemAndServicesAcquisition"
    "SC" = "SC-SystemAndCommunicationsProtection"
    "SI" = "SI-SystemAndInformationIntegrity"
    "SR" = "SR-SupplyChainRiskManagement"
}

# Create control family folders
foreach ($family in $controlFamilies.Values) {
    $folderPath = Join-Path $OutputPath $family
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        Write-Host "Created folder: $family"
    }
}

# Group policies by control family
$policyGroups = @{}
foreach ($policy in $policies) {
    $policyId = $policy.PolicyDefinitionId
    $groupNames = $policy.GroupName
    
    if ($groupNames -and $groupNames.Count -gt 0) {
        # Extract control family from first group name
        # Format: NIST_SP_800-53_R5_AC-2
        $firstGroup = $groupNames[0]
        if ($firstGroup -match "NIST_SP_800-53_R5_([A-Z]+)") {
            $familyCode = $Matches[1]
            $familyFolder = $controlFamilies[$familyCode]
            
            if ($familyFolder) {
                if (-not $policyGroups.ContainsKey($familyFolder)) {
                    $policyGroups[$familyFolder] = @()
                }
                $policyGroups[$familyFolder] += $policy
            }
        }
    }
}

# Report statistics
Write-Host ""
Write-Host "Policy Distribution by Control Family:"
Write-Host "======================================="
foreach ($family in $controlFamilies.Values | Sort-Object) {
    $count = if ($policyGroups.ContainsKey($family)) { $policyGroups[$family].Count } else { 0 }
    Write-Host "$family : $count policies"
}

# Export policy list by control family
$exportData = @()
foreach ($family in $controlFamilies.Values | Sort-Object) {
    if ($policyGroups.ContainsKey($family)) {
        foreach ($policy in $policyGroups[$family]) {
            $exportData += [PSCustomObject]@{
                ControlFamily = $family
                PolicyId = $policy.PolicyDefinitionId
                ReferenceId = $policy.Id
                GroupNames = ($policy.GroupName -join "; ")
            }
        }
    }
}

$exportData | Export-Csv -Path "nist-policies-by-control-family.csv" -NoTypeInformation
Write-Host ""
Write-Host "Exported policy mapping to nist-policies-by-control-family.csv"
