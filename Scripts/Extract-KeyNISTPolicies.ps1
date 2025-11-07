# Extract key NIST policies from R5 initiative and organize by control family
param(
    [string]$OutputPath = "Definitions/policyDefinitions",
    [int]$MaxPoliciesPerFamily = 10
)

Write-Host "Extracting key NIST policies from R5 initiative..."

# Get R5 initiative
$initiative = Get-AzPolicySetDefinition -Name "179d1daa-458f-4e47-8086-2a68d0d6c38f"
$policies = $initiative.Properties.PolicyDefinitions

Write-Host "Found $($policies.Count) policies in R5 initiative"
Write-Host ""

# Control family mapping
$controlFamilies = @{
    "AC" = "AC-AccessControl"
    "AU" = "AU-AuditAndAccountability"
    "CM" = "CM-ConfigurationManagement"
    "CP" = "CP-ContingencyPlanning"
    "IA" = "IA-IdentificationAndAuthentication"
    "IR" = "IR-IncidentResponse"
    "RA" = "RA-RiskAssessment"
    "SC" = "SC-SystemAndCommunicationsProtection"
    "SI" = "SI-SystemAndInformationIntegrity"
}

# Group policies by control family
$policyGroups = @{}
foreach ($policy in $policies) {
    $groupNames = $policy.GroupName
    
    if ($groupNames -and $groupNames.Count -gt 0) {
        foreach ($group in $groupNames) {
            if ($group -match "NIST_SP_800-53_R5_([A-Z]+)") {
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
}

# Extract top policies for each family
$extracted = 0
$failed = 0

foreach ($family in $controlFamilies.Values | Sort-Object) {
    if ($policyGroups.ContainsKey($family)) {
        $familyPolicies = $policyGroups[$family] | Select-Object -First $MaxPoliciesPerFamily
        
        Write-Host "Processing $family ($($familyPolicies.Count) policies)..."
        
        foreach ($policy in $familyPolicies) {
            $policyId = $policy.PolicyDefinitionId -replace ".*/policyDefinitions/", ""
            
            try {
                # Get the full policy definition
                $policyDef = Get-AzPolicyDefinition -Id $policy.PolicyDefinitionId
                
                # Create policy JSON
                $policyJson = @{
                    name = $policyDef.Name
                    properties = @{
                        displayName = $policyDef.Properties.DisplayName
                        policyType = $policyDef.Properties.PolicyType
                        mode = $policyDef.Properties.Mode
                        description = $policyDef.Properties.Description
                        metadata = $policyDef.Properties.Metadata
                        parameters = $policyDef.Properties.Parameters
                        policyRule = $policyDef.Properties.PolicyRule
                    }
                }
                
                # Save to control family folder
                $outputFile = Join-Path $OutputPath $family "$policyId.json"
                $policyJson | ConvertTo-Json -Depth 100 | Out-File $outputFile -Encoding UTF8
                
                Write-Host "  ✓ Extracted $policyId" -ForegroundColor Green
                $extracted++
            }
            catch {
                Write-Host "  ✗ Failed to extract $policyId : $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        }
    } else {
        Write-Host "No policies found for $family" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Extraction Summary:"
Write-Host "==================="
Write-Host "Extracted: $extracted"
Write-Host "Failed: $failed"
Write-Host "Total families: $($controlFamilies.Count)"

# Show folder contents
Write-Host ""
Write-Host "Folder Contents:"
foreach ($family in $controlFamilies.Values | Sort-Object) {
    $folderPath = Join-Path $OutputPath $family
    $fileCount = (Get-ChildItem $folderPath -Filter "*.json" -ErrorAction SilentlyContinue).Count
    Write-Host "$family : $fileCount policies"
}
