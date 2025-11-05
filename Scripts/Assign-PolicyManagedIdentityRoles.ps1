#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Assigns roles to NIST 800-53 policy assignment managed identities for remediation.

.DESCRIPTION
    This script assigns necessary Azure RBAC roles to the system-assigned managed identity
    created by the NIST 800-53 policy assignment. These roles are required for
    DeployIfNotExists and Modify policy effects to function properly.

.PARAMETER PacEnvironmentSelector
    The PAC environment selector (e.g., 'epac-dev', 'tenant')

.PARAMETER AssignmentName
    The policy assignment name (default: 'nist-800-53-r5')

.PARAMETER WaitForIdentity
    Wait for the managed identity to be created (in minutes, default: 5)

.PARAMETER DryRun
    Show what would be done without making changes

.EXAMPLE
    ./Scripts/Assign-PolicyManagedIdentityRoles.ps1 -PacEnvironmentSelector epac-dev

.EXAMPLE
    ./Scripts/Assign-PolicyManagedIdentityRoles.ps1 -PacEnvironmentSelector tenant -WaitForIdentity 10

.NOTES
    Run this script AFTER deploying the policy assignment with Deploy-PolicyPlan.
    The managed identity takes 5-10 minutes to propagate after policy deployment.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PacEnvironmentSelector,

    [Parameter(Mandatory = $false)]
    [string]$AssignmentName = "nist-800-53-r5",

    [Parameter(Mandatory = $false)]
    [int]$WaitForIdentity = 5,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Load EPAC module
Import-Module EnterprisePolicyAsCode -ErrorAction Stop

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "NIST 800-53 Managed Identity Role Assignment" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Load global settings to get deployment root scope
$globalSettingsFile = "./Definitions/global-settings.jsonc"
if (-not (Test-Path $globalSettingsFile)) {
    Write-Error "Global settings file not found: $globalSettingsFile"
    exit 1
}

$globalSettings = Get-Content $globalSettingsFile -Raw | ConvertFrom-Json
$pacEnvironment = $globalSettings.pacEnvironments | Where-Object { $_.pacSelector -eq $PacEnvironmentSelector }

if (-not $pacEnvironment) {
    Write-Error "PAC environment '$PacEnvironmentSelector' not found in global settings"
    exit 1
}

Write-Host "Environment: $PacEnvironmentSelector" -ForegroundColor Green
Write-Host "Tenant ID: $($pacEnvironment.tenantId)" -ForegroundColor Green
Write-Host "Deployment Root: $($pacEnvironment.deploymentRootScope)" -ForegroundColor Green
Write-Host ""

# Connect to Azure if not already connected
$context = Get-AzContext
if (-not $context -or $context.Tenant.Id -ne $pacEnvironment.tenantId) {
    Write-Host "Connecting to Azure tenant: $($pacEnvironment.tenantId)" -ForegroundColor Yellow
    Connect-AzAccount -Tenant $pacEnvironment.tenantId
}

# Extract management group ID from deployment root scope
$mgId = $pacEnvironment.deploymentRootScope -replace '.*managementGroups/', ''

# Wait for managed identity to be created
if ($WaitForIdentity -gt 0) {
    Write-Host "Waiting $WaitForIdentity minutes for managed identity to propagate..." -ForegroundColor Yellow
    Start-Sleep -Seconds ($WaitForIdentity * 60)
}

# Get the policy assignment
Write-Host "Looking for policy assignment: $AssignmentName" -ForegroundColor Cyan
$assignment = Get-AzPolicyAssignment -Scope $pacEnvironment.deploymentRootScope |
    Where-Object { $_.Name -eq $AssignmentName }

if (-not $assignment) {
    Write-Error "Policy assignment '$AssignmentName' not found at scope: $($pacEnvironment.deploymentRootScope)"
    exit 1
}

# Check if managed identity exists
if (-not $assignment.Identity -or -not $assignment.Identity.PrincipalId) {
    Write-Error "Policy assignment does not have a managed identity. Ensure the assignment has 'identity: { type: SystemAssigned }' configured."
    exit 1
}

$principalId = $assignment.Identity.PrincipalId
Write-Host "Found managed identity: $principalId" -ForegroundColor Green
Write-Host ""

# Define roles needed for NIST 800-53 remediation
# These roles cover the common DeployIfNotExists and Modify policies
$rolesToAssign = @(
    @{
        Name = "Contributor"
        Description = "Required for most DeployIfNotExists policies"
    },
    @{
        Name = "Log Analytics Contributor"
        Description = "Required for diagnostic settings and monitoring policies"
    },
    @{
        Name = "Security Admin"
        Description = "Required for security configuration policies"
    },
    @{
        Name = "Monitoring Contributor"
        Description = "Required for Azure Monitor and diagnostic policies"
    },
    @{
        Name = "Virtual Machine Contributor"
        Description = "Required for VM extension deployment and modification"
    }
)

Write-Host "Roles to assign at scope: $($pacEnvironment.deploymentRootScope)" -ForegroundColor Cyan
foreach ($role in $rolesToAssign) {
    Write-Host "  - $($role.Name): $($role.Description)" -ForegroundColor White
}
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Assign roles
$assignedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($roleInfo in $rolesToAssign) {
    try {
        # Check if role assignment already exists
        $existingAssignment = Get-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName $roleInfo.Name -Scope $pacEnvironment.deploymentRootScope -ErrorAction SilentlyContinue

        if ($existingAssignment) {
            Write-Host "✓ SKIP: $($roleInfo.Name) - Already assigned" -ForegroundColor Yellow
            $skippedCount++
        }
        else {
            if (-not $DryRun) {
                New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName $roleInfo.Name -Scope $pacEnvironment.deploymentRootScope -ErrorAction Stop | Out-Null
                Write-Host "✓ ASSIGNED: $($roleInfo.Name)" -ForegroundColor Green
                $assignedCount++
            }
            else {
                Write-Host "✓ WOULD ASSIGN: $($roleInfo.Name)" -ForegroundColor Cyan
            }
        }
    }
    catch {
        Write-Host "✗ ERROR: $($roleInfo.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Assigned: $assignedCount" -ForegroundColor Green
Write-Host "Skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($assignedCount -gt 0) {
    Write-Host "Role assignments created successfully!" -ForegroundColor Green
    Write-Host "Note: Role assignments may take 5-10 minutes to propagate before remediation works." -ForegroundColor Yellow
}

if ($errorCount -gt 0) {
    Write-Host "Some role assignments failed. Check errors above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Wait 5-10 minutes for role assignments to propagate" -ForegroundColor White
Write-Host "2. Test remediation with: Start-AzPolicyRemediation" -ForegroundColor White
Write-Host "3. Check policy compliance in Azure Portal" -ForegroundColor White
