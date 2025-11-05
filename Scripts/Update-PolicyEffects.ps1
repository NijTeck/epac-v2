#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates NIST 800-53 policy effects in the CSV for phased enforcement rollout.

.DESCRIPTION
    This script helps transition policies from Audit mode to enforcement mode (Deny, DeployIfNotExists)
    in a controlled, phased manner. It can update effects for specific policies or policy groups.

.PARAMETER Phase
    The rollout phase (1-5) as defined in ENFORCEMENT_MODE_ROLLOUT_PLAN.md

.PARAMETER PolicyIds
    Array of specific policy GUIDs to update

.PARAMETER Effect
    The effect to apply (Deny, DeployIfNotExists, Modify, AuditIfNotExists)

.PARAMETER Environment
    Target environment: prod, nonprod, or both (default: both)

.PARAMETER DryRun
    Show what would be changed without making changes

.EXAMPLE
    ./Scripts/Update-PolicyEffects.ps1 -Phase 1 -DryRun

.EXAMPLE
    ./Scripts/Update-PolicyEffects.ps1 -PolicyIds "a4af4a39-4135-47fb-b175-47fbdf85311d" -Effect Deny -Environment prod

.NOTES
    Always backup the CSV before making changes. Use -DryRun first to preview changes.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 5)]
    [int]$Phase,

    [Parameter(Mandatory = $false)]
    [string[]]$PolicyIds,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Audit", "AuditIfNotExists", "Deny", "DeployIfNotExists", "Modify", "Disabled")]
    [string]$Effect,

    [Parameter(Mandatory = $false)]
    [ValidateSet("prod", "nonprod", "both")]
    [string]$Environment = "both",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Backup = $true
)

$ErrorActionPreference = "Stop"

$csvPath = "./Definitions/policyAssignments/nist-800-53-parameters.csv"

if (-not (Test-Path $csvPath)) {
    Write-Error "CSV file not found: $csvPath"
    exit 1
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "NIST 800-53 Policy Effect Updater" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Create backup
if ($Backup -and -not $DryRun) {
    $backupPath = "$csvPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $csvPath $backupPath
    Write-Host "✓ Backup created: $backupPath" -ForegroundColor Green
    Write-Host ""
}

# Define policy groups for each phase
$phaseDefinitions = @{
    1 = @{
        Name        = "Phase 1: Low-Risk Network Policies (Dev Testing)"
        Description = "5 low-risk policies for initial dev testing"
        Policies    = @(
            "0e60b895-3786-45da-8377-9c6b4b6ac5f9", # Storage restrict network
            "3d9f5e4c-9947-4579-9539-2a7695fbc187", # Storage private link
            "c9299215-ae47-4f50-9c54-8a392f68a052", # MySQL disable public network
            "5e1de0e3-42cb-4ebc-a86d-61d0c619ca48", # PostgreSQL disable public network
            "ef619a2c-cc4d-4d03-b2ba-8c94a834d85b"  # API Management use VNET
        )
        Effect      = "Deny"
    }
    2 = @{
        Name        = "Phase 2: Network Security & TLS"
        Description = "15 network and encryption-in-transit policies"
        Policies    = @(
            # Network isolation (8)
            "0e60b895-3786-45da-8377-9c6b4b6ac5f9",
            "3d9f5e4c-9947-4579-9539-2a7695fbc187",
            "ca610c1d-041c-4332-9d88-7ed3094967c7",
            "58440f8a-10c5-4151-bdce-dfbaad4a20b7",
            "e8cbc669-f12d-49eb-93e7-9273119e9933",
            "7698e800-9299-47a4-b607-3b6a2c6bd37c",
            "1b8ca024-1d5c-4dec-8995-b1a932b41780",
            "c9299215-ae47-4f50-9c54-8a392f68a052",
            # TLS/HTTPS (7)
            "a4af4a39-4135-47fb-b175-47fbdf85311d",
            "6d555dd1-86f2-4f1c-8ed7-5abae7c6cbab",
            "404c3081-a854-4457-ae30-26a93ef643f9",
            "22bee202-a82f-4305-9a2a-6d7f44d4dedb",
            "e8cbc669-f12d-49eb-93e7-9273119e9933",
            "f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b",
            "8c122334-9d20-4eb8-89ea-ac9a705b74ae"
        )
        Effect      = "Deny"
    }
    3 = @{
        Name        = "Phase 3: Compute & Identity"
        Description = "VM security and IAM policies"
        Policies    = @(
            # VM security
            "efbde977-ba53-4479-b8e9-10b957924fbf",
            "702dd420-7fcc-42c5-afe8-4026edd20fe0",
            "465f0161-0087-490a-9ad9-ad6217f4f43a"
        )
        Effect      = "AuditIfNotExists"
    }
    4 = @{
        Name        = "Phase 4: Remediation Policies"
        Description = "DeployIfNotExists policies for auto-remediation"
        Policies    = @(
            # Diagnostic settings
            "b79fa14e-238a-4c2d-b376-442ce508fc84",
            "cf820ca0-f99e-4f3e-84fb-66e913812d21"
        )
        Effect      = "DeployIfNotExists"
    }
    5 = @{
        Name        = "Phase 5: Comprehensive Enforcement"
        Description = "Remaining high-value policies"
        Policies    = @()
        Effect      = "Varies"
    }
}

# Load CSV
$csv = Import-Csv -Path $csvPath

# Determine which policies to update
$policiesToUpdate = @()

if ($Phase) {
    $phaseDef = $phaseDefinitions[$Phase]
    Write-Host "Phase: $($phaseDef.Name)" -ForegroundColor Cyan
    Write-Host "Description: $($phaseDef.Description)" -ForegroundColor White
    Write-Host ""

    $policiesToUpdate = $phaseDef.Policies
    if (-not $Effect) {
        $Effect = $phaseDef.Effect
    }
}
elseif ($PolicyIds) {
    $policiesToUpdate = $PolicyIds
}
else {
    Write-Error "Must specify either -Phase or -PolicyIds"
    exit 1
}

if (-not $Effect) {
    Write-Error "Must specify -Effect when using -PolicyIds"
    exit 1
}

Write-Host "Effect to apply: $Effect" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Policies to update: $($policiesToUpdate.Count)" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    Write-Host ""
}

# Update policies
$updatedCount = 0
$notFoundCount = 0

foreach ($policyId in $policiesToUpdate) {
    $policy = $csv | Where-Object { $_.name -eq $policyId }

    if ($policy) {
        $displayName = $policy.displayName
        $currentProd = $policy.prodEffect
        $currentNonprod = $policy.nonprodEffect

        # Determine new effects based on environment
        $newProd = if ($Environment -in @("prod", "both")) { $Effect } else { $currentProd }
        $newNonprod = if ($Environment -in @("nonprod", "both")) { $Effect } else { $currentNonprod }

        Write-Host "Policy: $displayName" -ForegroundColor White
        Write-Host "  ID: $policyId" -ForegroundColor Gray
        Write-Host "  Current: prod=$currentProd, nonprod=$currentNonprod" -ForegroundColor Gray
        Write-Host "  New:     prod=$newProd, nonprod=$newNonprod" -ForegroundColor $(if ($DryRun) { "Cyan" } else { "Green" })
        Write-Host ""

        if (-not $DryRun) {
            $policy.prodEffect = $newProd
            $policy.nonprodEffect = $newNonprod
            $updatedCount++
        }
    }
    else {
        Write-Host "✗ Policy not found: $policyId" -ForegroundColor Red
        $notFoundCount++
    }
}

# Save CSV if not dry run
if (-not $DryRun -and $updatedCount -gt 0) {
    $csv | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "✓ CSV updated successfully!" -ForegroundColor Green
    Write-Host "  Updated: $updatedCount policies" -ForegroundColor Green
    Write-Host "  Not found: $notFoundCount policies" -ForegroundColor $(if ($notFoundCount -gt 0) { "Red" } else { "Green" })
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Review changes: git diff $csvPath" -ForegroundColor White
    Write-Host "2. Test deployment: Build-DeploymentPlans -PacEnvironmentSelector epac-dev" -ForegroundColor White
    Write-Host "3. Deploy to environment" -ForegroundColor White
}
elseif ($DryRun) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Dry run complete - no changes made" -ForegroundColor Yellow
    Write-Host "  Would update: $($policiesToUpdate.Count) policies" -ForegroundColor Yellow
    Write-Host "  Not found: $notFoundCount policies" -ForegroundColor $(if ($notFoundCount -gt 0) { "Red" } else { "Green" })
    Write-Host ""
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor White
}

Write-Host ""
