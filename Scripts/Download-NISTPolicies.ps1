# Download NIST SP 800-53 R5.1.1 policy definitions from GitHub
param(
    [string]$PolicySetPath = "nist-r5-1-1-policyset.json",
    [string]$OutputPath = "Definitions/policyDefinitions",
    [string]$GitHubBaseUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions"
)

Write-Host "Loading policy set from $PolicySetPath..."
$policySet = Get-Content $PolicySetPath | ConvertFrom-Json
$policies = $policySet.properties.policyDefinitions

Write-Host "Found $($policies.Count) policy references"
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

# Create control family folders
foreach ($family in $controlFamilies.Values) {
    $folderPath = Join-Path $OutputPath $family
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
    }
}

# Track downloads
$downloaded = 0
$failed = 0
$skipped = 0

# Download each policy
foreach ($policyRef in $policies) {
    $policyId = $policyRef.policyDefinitionId -replace ".*/policyDefinitions/", ""
    $groupNames = $policyRef.groupNames
    
    # Determine control family from first group
    $familyFolder = $null
    if ($groupNames -and $groupNames.Count -gt 0) {
        $firstGroup = $groupNames[0]
        if ($firstGroup -match "NIST_SP_800-53_R5_([A-Z]+)") {
            $familyCode = $Matches[1]
            $familyFolder = $controlFamilies[$familyCode]
        }
    }
    
    if (-not $familyFolder) {
        Write-Host "Skipping $policyId - no control family found" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    # Try to find the policy in GitHub
    $categories = @(
        "Compute", "Monitoring", "Network", "Security Center", "Storage", "SQL", 
        "Key Vault", "Kubernetes", "App Service", "Cosmos DB", "Azure Data Explorer",
        "API Management", "App Configuration", "Automation", "Batch", "Cache",
        "Cognitive Services", "Container Registry", "Data Factory", "Event Hub",
        "Guest Configuration", "HDInsight", "IoT", "Logic Apps", "Machine Learning",
        "Media Services", "Service Bus", "Service Fabric", "SignalR", "Stream Analytics",
        "Synapse", "Tags"
    )
    
    $policyDownloaded = $false
    foreach ($category in $categories) {
        $url = "$GitHubBaseUrl/$category/$policyId.json"
        
        try {
            $policyDef = Invoke-RestMethod -Uri $url -ErrorAction Stop
            
            # Save to control family folder
            $outputFile = Join-Path $OutputPath $familyFolder "$policyId.json"
            $policyDef | ConvertTo-Json -Depth 100 | Out-File $outputFile -Encoding UTF8
            
            Write-Host "Downloaded $policyId to $familyFolder" -ForegroundColor Green
            $downloaded++
            $policyDownloaded = $true
            break
        }
        catch {
            continue
        }
    }
    
    if (-not $policyDownloaded) {
        Write-Host "Failed to download $policyId" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Download Summary:"
Write-Host "================="
Write-Host "Downloaded: $downloaded"
Write-Host "Failed: $failed"
Write-Host "Skipped: $skipped"
$total = $policies.Count
Write-Host "Total: $total"
