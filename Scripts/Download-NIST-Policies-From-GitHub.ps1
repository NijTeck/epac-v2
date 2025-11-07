# Download NIST R5 policies from GitHub with full content
param(
    [string]$OutputPath = "Definitions/policyDefinitions",
    [int]$MaxPoliciesPerFamily = 10
)

Write-Host "Downloading NIST R5 policy set metadata..."

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

# Group by control family (take first N per family)
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

$downloaded = 0
$failed = 0
$baseUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions"

# Extended list of categories
$categories = @(
    "API Management", "App Configuration", "App Platform", "App Service", "Attestation",
    "Automanage", "Automation", "Azure Data Explorer", "Azure Stack Edge", "Backup",
    "Batch", "Bot Service", "Cache", "Cognitive Services", "Compute", "Container Instance",
    "Container Registry", "Cosmos DB", "Custom Provider", "Data Box", "Data Factory",
    "Data Lake", "Event Grid", "Event Hub", "General", "Guest Configuration", "HDInsight",
    "Internet of Things", "Key Vault", "Kubernetes", "Lighthouse", "Logic Apps",
    "Machine Learning", "Managed Application", "Media Services", "Migrate", "Monitoring",
    "Network", "Portal", "Recovery Services Vault", "Resilience", "Search",
    "Security Center", "Service Bus", "Service Fabric", "SignalR", "Site Recovery",
    "SQL", "Storage", "Stream Analytics", "Synapse", "Tags", "VM Image Builder"
)

foreach ($family in $policyGroups.Keys | Sort-Object) {
    Write-Host "Downloading $family policies..."
    
    foreach ($policyRef in $policyGroups[$family]) {
        $policyId = $policyRef.policyDefinitionId -replace ".*/policyDefinitions/", ""
        
        $found = $false
        foreach ($category in $categories) {
            $url = "$baseUrl/$category/$policyId.json"
            
            try {
                $policyDef = Invoke-RestMethod -Uri $url -ErrorAction Stop
                
                # Save with full content
                $outputFile = Join-Path $OutputPath $family "$policyId.json"
                $policyDef | ConvertTo-Json -Depth 100 | Out-File $outputFile -Encoding UTF8
                
                Write-Host "  Downloaded: $policyId" -ForegroundColor Green
                $downloaded++
                $found = $true
                break
            }
            catch {
                continue
            }
        }
        
        if (-not $found) {
            Write-Host "  Failed: $policyId" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Download Summary:"
Write-Host "================="
Write-Host "Downloaded: $downloaded"
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
