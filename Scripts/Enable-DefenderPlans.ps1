#Requires -Modules Az.Security, Az.Accounts

<#
.SYNOPSIS
    Enables Microsoft Defender plans for Azure subscriptions to meet NIST 800-53 compliance.

.DESCRIPTION
    This script automatically enables Microsoft Defender plans that are required by NIST 800-53 policies.
    These plans cannot be enabled via Azure Policy DeployIfNotExists, so they must be enabled separately.

.PARAMETER SubscriptionIds
    Array of subscription IDs to enable Defender plans for. If not specified, uses current subscription.

.PARAMETER DefenderPlans
    Array of Defender plan names to enable. Defaults to all NIST 800-53 required plans.

.EXAMPLE
    .\Enable-DefenderPlans.ps1 -SubscriptionIds @("sub-id-1", "sub-id-2")

.EXAMPLE
    .\Enable-DefenderPlans.ps1 -DefenderPlans @("VirtualMachines", "SqlServers", "AppServices")
#>

param(
    [Parameter(Mandatory=$false)]
    [string[]]$SubscriptionIds,
    
    [Parameter(Mandatory=$false)]
    [string[]]$DefenderPlans = @(
        "VirtualMachines",           # Azure Defender for servers
        "SqlServers",                # Azure Defender for SQL servers on machines
        "AppServices",               # Azure Defender for App Service
        "StorageAccounts",           # Microsoft Defender for Storage
        "SqlServerVirtualMachines",  # Azure Defender for SQL
        "KubernetesService",         # Microsoft Defender for Containers
        "ContainerRegistry",         # Microsoft Defender for container registries
        "KeyVaults",                 # Azure Defender for Key Vault
        "Dns",                       # Azure Defender for DNS
        "Arm",                       # Azure Defender for Resource Manager
        "OpenSourceRelationalDatabases"  # Azure Defender for open-source relational databases
    )
)

# Get subscriptions to process
if (-not $SubscriptionIds) {
    $context = Get-AzContext
    $SubscriptionIds = @($context.Subscription.Id)
    Write-Host "No subscription IDs specified. Using current subscription: $($context.Subscription.Name)" -ForegroundColor Yellow
}

Write-Host "=== Enabling Microsoft Defender Plans ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Subscriptions to process: $($SubscriptionIds.Count)" -ForegroundColor Yellow
Write-Host "Defender plans to enable: $($DefenderPlans.Count)" -ForegroundColor Yellow
Write-Host ""

$results = @()

foreach ($subId in $SubscriptionIds) {
    Write-Host "Processing subscription: $subId" -ForegroundColor Cyan
    
    # Set context to subscription
    try {
        Set-AzContext -SubscriptionId $subId -ErrorAction Stop | Out-Null
        $subscription = Get-AzSubscription -SubscriptionId $subId
        Write-Host "  Subscription Name: $($subscription.Name)" -ForegroundColor White
    }
    catch {
        Write-Host "  ✗ Failed to set context: $($_.Exception.Message)" -ForegroundColor Red
        continue
    }
    
    foreach ($plan in $DefenderPlans) {
        Write-Host "  Enabling plan: $plan" -ForegroundColor Yellow
        
        try {
            # Check current status
            $currentPricing = Get-AzSecurityPricing -Name $plan -ErrorAction SilentlyContinue
            
            if ($currentPricing.PricingTier -eq "Standard") {
                Write-Host "    ✓ Already enabled" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    Subscription = $subscription.Name
                    SubscriptionId = $subId
                    DefenderPlan = $plan
                    Status = "Already Enabled"
                    PricingTier = "Standard"
                }
            }
            else {
                # Enable the plan
                Set-AzSecurityPricing -Name $plan -PricingTier "Standard" -ErrorAction Stop | Out-Null
                Write-Host "    ✓ Enabled successfully" -ForegroundColor Green
                
                $results += [PSCustomObject]@{
                    Subscription = $subscription.Name
                    SubscriptionId = $subId
                    DefenderPlan = $plan
                    Status = "Enabled"
                    PricingTier = "Standard"
                }
            }
        }
        catch {
            Write-Host "    ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
            
            $results += [PSCustomObject]@{
                Subscription = $subscription.Name
                SubscriptionId = $subId
                DefenderPlan = $plan
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""
$results | Format-Table -AutoSize

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$results | Export-Csv "defender-plans-enablement-$timestamp.csv" -NoTypeInformation
Write-Host "Results exported to: defender-plans-enablement-$timestamp.csv" -ForegroundColor Green

# Count successes and failures
$enabled = ($results | Where-Object { $_.Status -in @("Enabled", "Already Enabled") }).Count
$failed = ($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host ""
Write-Host "Total plans processed: $($results.Count)" -ForegroundColor Yellow
Write-Host "Successfully enabled: $enabled" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed plans:" -ForegroundColor Red
    $results | Where-Object { $_.Status -eq "Failed" } | Format-Table Subscription, DefenderPlan, Error -AutoSize
}
