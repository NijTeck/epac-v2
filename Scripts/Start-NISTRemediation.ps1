<#
.SYNOPSIS
    Trigger NIST 800-53 compliance remediation for non-compliant resources
.DESCRIPTION
    This script creates and monitors Azure Policy remediation tasks for NIST 800-53 non-compliant resources
.PARAMETER ManagementGroupId
    The management group ID to remediate (default: Tenant Root Group)
.PARAMETER Environment
    The environment to remediate (EPAC-DEV or TENANT)
.PARAMETER WaitForCompletion
    Wait for remediation to complete before returning
.EXAMPLE
    .\Start-NISTRemediation.ps1 -Environment TENANT -WaitForCompletion
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ManagementGroupId = "e1f3e196-aa55-4709-9c55-0e334c0b444f",

    [Parameter()]
    [ValidateSet("EPAC-DEV", "TENANT")]
    [string]$Environment = "TENANT",

    [Parameter()]
    [switch]$WaitForCompletion
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "NIST 800-53 Remediation Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$context = Get-AzContext
if (-not $context) {
    Write-Host "Not logged in to Azure. Please run 'Connect-AzAccount' first." -ForegroundColor Red
    exit 1
}

Write-Host "Logged in as: $($context.Account.Id)" -ForegroundColor Green
Write-Host "Tenant: $($context.Tenant.Id)" -ForegroundColor Green
Write-Host ""

# Get compliance state
Write-Host "Checking current compliance state..." -ForegroundColor Yellow

$nonCompliantResources = Get-AzPolicyState `
    -ManagementGroupName $ManagementGroupId `
    -Filter "ComplianceState eq 'NonCompliant' and PolicySetDefinitionName eq 'NIST SP 800-53 Rev. 5'" `
    -Select "ResourceId, PolicyDefinitionName, PolicyDefinitionAction"

$totalNonCompliant = ($nonCompliantResources | Measure-Object).Count

if ($totalNonCompliant -eq 0) {
    Write-Host "✨ All resources are compliant! No remediation needed." -ForegroundColor Green
    exit 0
}

Write-Host "Found $totalNonCompliant non-compliant resources" -ForegroundColor Yellow
Write-Host ""

# Group by policy definition for better visibility
$groupedPolicies = $nonCompliantResources | Group-Object -Property PolicyDefinitionName

Write-Host "Non-compliant policies breakdown:" -ForegroundColor Cyan
foreach ($group in $groupedPolicies) {
    Write-Host "  - $($group.Name): $($group.Count) resources" -ForegroundColor White
}
Write-Host ""

# Get policy assignment
Write-Host "Getting policy assignment..." -ForegroundColor Yellow
$assignment = Get-AzPolicyAssignment `
    -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupId" |
    Where-Object { $_.Properties.DisplayName -eq "NIST SP 800-53 Rev. 5" } |
    Select-Object -First 1

if (-not $assignment) {
    Write-Host "Error: NIST 800-53 policy assignment not found" -ForegroundColor Red
    exit 1
}

Write-Host "Found assignment: $($assignment.Name)" -ForegroundColor Green
Write-Host ""

# Create remediation task
$taskName = "NIST-Remediation-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Creating remediation task: $taskName" -ForegroundColor Yellow

try {
    $remediationTask = Start-AzPolicyRemediation `
        -Name $taskName `
        -PolicyAssignmentId $assignment.ResourceId `
        -ManagementGroupName $ManagementGroupId `
        -ResourceDiscoveryMode ReEvaluateCompliance `
        -FailureThreshold 0.5 `
        -ParallelDeployments 10 `
        -ResourceCount 500

    Write-Host "✅ Remediation task created successfully" -ForegroundColor Green
    Write-Host "Task ID: $($remediationTask.Name)" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "Error creating remediation task: $_" -ForegroundColor Red
    exit 1
}

# Monitor remediation if requested
if ($WaitForCompletion) {
    Write-Host "Monitoring remediation progress..." -ForegroundColor Yellow
    Write-Host "This may take several minutes..." -ForegroundColor Gray
    Write-Host ""

    $timeout = 1800  # 30 minutes
    $startTime = Get-Date
    $lastProgress = @{
        Total = 0
        Successful = 0
        Failed = 0
    }

    while ($true) {
        Start-Sleep -Seconds 30

        # Get current status
        $status = Get-AzPolicyRemediation `
            -Name $taskName `
            -ManagementGroupName $ManagementGroupId

        $currentProgress = @{
            Total = $status.Properties.DeploymentStatus.TotalDeployments
            Successful = $status.Properties.DeploymentStatus.SuccessfulDeployments
            Failed = $status.Properties.DeploymentStatus.FailedDeployments
        }

        # Only display if progress changed
        if ($currentProgress.Total -ne $lastProgress.Total -or
            $currentProgress.Successful -ne $lastProgress.Successful -or
            $currentProgress.Failed -ne $lastProgress.Failed) {

            $percentComplete = if ($currentProgress.Total -gt 0) {
                [math]::Round(($currentProgress.Successful / $currentProgress.Total) * 100, 2)
            } else { 0 }

            Write-Progress `
                -Activity "Remediating NIST 800-53 Non-Compliance" `
                -Status "State: $($status.Properties.ProvisioningState)" `
                -PercentComplete $percentComplete `
                -CurrentOperation "Deployments: $($currentProgress.Successful)/$($currentProgress.Total) successful, $($currentProgress.Failed) failed"

            $lastProgress = $currentProgress
        }

        # Check if completed
        if ($status.Properties.ProvisioningState -in @("Succeeded", "Failed", "Canceled")) {
            Write-Progress -Activity "Remediating NIST 800-53 Non-Compliance" -Completed

            Write-Host ""
            Write-Host "=====================================" -ForegroundColor Cyan
            Write-Host "Remediation Completed" -ForegroundColor Cyan
            Write-Host "=====================================" -ForegroundColor Cyan
            Write-Host "Status: $($status.Properties.ProvisioningState)" -ForegroundColor $(if ($status.Properties.ProvisioningState -eq "Succeeded") { "Green" } else { "Yellow" })
            Write-Host "Total Deployments: $($currentProgress.Total)" -ForegroundColor White
            Write-Host "Successful: $($currentProgress.Successful)" -ForegroundColor Green
            Write-Host "Failed: $($currentProgress.Failed)" -ForegroundColor $(if ($currentProgress.Failed -gt 0) { "Red" } else { "Gray" })
            Write-Host ""

            break
        }

        # Check timeout
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -gt $timeout) {
            Write-Host "Warning: Remediation timed out after 30 minutes" -ForegroundColor Yellow
            Write-Host "The task will continue running in the background" -ForegroundColor Yellow
            break
        }
    }
}

# Generate summary report
Write-Host "Generating compliance summary..." -ForegroundColor Yellow

# Re-check compliance after remediation
Start-Sleep -Seconds 10  # Brief wait for state to update
$newNonCompliantResources = Get-AzPolicyState `
    -ManagementGroupName $ManagementGroupId `
    -Filter "ComplianceState eq 'NonCompliant' and PolicySetDefinitionName eq 'NIST SP 800-53 Rev. 5'" `
    -Select "ResourceId"

$newTotalNonCompliant = ($newNonCompliantResources | Measure-Object).Count
$resourcesRemediated = $totalNonCompliant - $newTotalNonCompliant

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "Remediation Summary" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "Resources remediated: $resourcesRemediated" -ForegroundColor White
Write-Host "Remaining non-compliant: $newTotalNonCompliant" -ForegroundColor $(if ($newTotalNonCompliant -gt 0) { "Yellow" } else { "Green" })

if ($newTotalNonCompliant -gt 0) {
    $compliancePercent = [math]::Round((1 - ($newTotalNonCompliant / 12)) * 100, 2)
    Write-Host "Compliance level: $compliancePercent%" -ForegroundColor White
} else {
    Write-Host "Compliance level: 100% ✅" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review remediation details in Azure Portal" -ForegroundColor White
Write-Host "2. Check resource logs for any failed deployments" -ForegroundColor White
Write-Host "3. Run this script again if needed" -ForegroundColor White
Write-Host ""

# Output task details for reference
$taskDetails = @{
    TaskName = $taskName
    ManagementGroup = $ManagementGroupId
    StartTime = $startTime
    ResourcesRemediated = $resourcesRemediated
    RemainingNonCompliant = $newTotalNonCompliant
}

Write-Host "Task details saved to: .\remediation-log.json" -ForegroundColor Gray
$taskDetails | ConvertTo-Json | Out-File -FilePath ".\remediation-log.json"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan