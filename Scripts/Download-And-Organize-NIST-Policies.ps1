# Download all 224 NIST R5.1.1 policies and organize by control family
param(
    [string]$OutputPath = "Definitions/policyDefinitions"
)

Write-Host "Downloading NIST SP 800-53 R5.1.1 policy set..."
$policySetUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policySetDefinitions/Regulatory%20Compliance/NIST_SP_800-53_R5.1.1.json"
$policySet = Invoke-RestMethod -Uri $policySetUrl

$policyIds = $policySet.properties.policyDefinitions | ForEach-Object {
    $_.policyDefinitionId -replace ".*/policyDefinitions/", ""
} | Select-Object -Unique

Write-Host "Found $($policyIds.Count) policies to download"
Write-Host ""

# GitHub API to search for policies
$githubApiUrl = "https://api.github.com/repos/Azure/azure-policy/contents/built-in-policies/policyDefinitions"

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

# Track progress
$downloaded = 0
$failed = 0
$total = $policyIds.Count

Write-Host "Downloading policies..."
foreach ($policyId in $policyIds) {
    $progress = [math]::Round(($downloaded + $failed) / $total * 100)
    Write-Progress -Activity "Downloading NIST Policies" -Status "$progress% Complete" -PercentComplete $progress
    
    # Try to download from GitHub raw
    $baseUrl = "https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions"
    
    # Try common categories
    $categories = @(
        "Compute", "Monitoring", "Network", "Security Center", "Storage", "SQL",
        "Key Vault", "Kubernetes", "App Service", "Cosmos DB", "Azure Data Explorer",
        "API Management", "App Configuration", "Automation", "Batch", "Cache",
        "Cognitive Services", "Container Registry", "Data Factory", "Event Hub",
        "Guest Configuration", "HDInsight", "IoT", "Logic Apps", "Machine Learning",
        "Media Services", "Service Bus", "Service Fabric", "SignalR", "Stream Analytics",
        "Synapse", "Tags", "Azure Automanage", "Bot Service", "Container Instance",
        "Data Lake", "Event Grid", "Lighthouse", "Managed Application", "Recovery Services Vault",
        "Search", "Site Recovery", "Spring Cloud", "Azure Stack Edge", "VM Image Builder"
    )
    
    $policyDownloaded = $false
    foreach ($category in $categories) {
        $url = "$baseUrl/$category/$policyId.json"
        
        try {
            $policyDef = Invoke-RestMethod -Uri $url -ErrorAction Stop
            
            # Determine control family from policy metadata or display name
            $familyFolder = "Uncategorized"
            
            # Check if policy has category metadata
            if ($policyDef.properties.metadata.category) {
                $cat = $policyDef.properties.metadata.category
                # Map category to control family (best guess)
                switch -Regex ($cat) {
                    "Security Center|Monitoring" { $familyFolder = "SI-SystemAndInformationIntegrity" }
                    "Network" { $familyFolder = "SC-SystemAndCommunicationsProtection" }
                    "Storage|Key Vault|Encryption" { $familyFolder = "SC-SystemAndCommunicationsProtection" }
                    "Compute|Kubernetes|Container" { $familyFolder = "CM-ConfigurationManagement" }
                    "Guest Configuration" { $familyFolder = "CM-ConfigurationManagement" }
                    "SQL|Cosmos DB|Database" { $familyFolder = "SC-SystemAndCommunicationsProtection" }
                    default { $familyFolder = "CM-ConfigurationManagement" }
                }
            }
            
            # Create folder if needed
            $folderPath = Join-Path $OutputPath $familyFolder
            if (-not (Test-Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            }
            
            # Save policy
            $outputFile = Join-Path $folderPath "$policyId.json"
            $policyDef | ConvertTo-Json -Depth 100 | Out-File $outputFile -Encoding UTF8
            
            $downloaded++
            $policyDownloaded = $true
            break
        }
        catch {
            continue
        }
    }
    
    if (-not $policyDownloaded) {
        Write-Host "Failed: $policyId" -ForegroundColor Red
        $failed++
    }
}

Write-Progress -Activity "Downloading NIST Policies" -Completed

Write-Host ""
Write-Host "Download Complete!"
Write-Host "=================="
Write-Host "Downloaded: $downloaded"
Write-Host "Failed: $failed"
Write-Host "Total: $total"
Write-Host ""
Write-Host "Policies organized in: $OutputPath"
